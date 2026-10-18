import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/app_icon.dart';
import 'package:money_tracker/core/dates.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/data/repository.dart';
import 'package:money_tracker/domain/recurrence_service.dart';

import 'helpers/test_repo.dart';

const _icon = ColorIcon('#FF0000', 'X');

Wallet _wallet(String uuid, {String currency = 'EUR', int start = 0, bool counted = true}) =>
    Wallet(uuid: uuid, name: uuid, icon: _icon, currency: currency,
        startMoney: start, countInTotal: counted);

Category _category(String uuid, int type, {String? parent}) =>
    Category(uuid: uuid, name: uuid, icon: _icon, type: type, parent: parent);

Transaction _tx(String uuid, int money, int direction,
        {String wallet = 'w1', String category = 'food', DateTime? date,
        bool confirmed = true, bool counted = true}) =>
    Transaction(
      uuid: uuid,
      money: money,
      date: date ?? DateTime(2024, 1, 10, 12),
      category: category,
      direction: direction,
      wallet: wallet,
      confirmed: confirmed,
      countInTotal: counted,
    );

void main() {
  late Repository repo;

  setUp(() {
    repo = createTestRepository();
    repo.saveWallet(_wallet('w1', start: 10000));
    repo.saveWallet(_wallet('w2'));
    repo.saveWallet(_wallet('usd', currency: 'USD', start: 500));
    repo.saveCategory(_category('food', CategoryType.expense));
    repo.saveCategory(_category('salary', CategoryType.income));
  });

  group('seeding', () {
    test('currencies and system categories', () {
      expect(repo.currencies().length, greaterThan(150));
      expect(repo.currency('EUR')!.decimals, 2);
      expect(repo.systemCategory(SystemTag.transfer).uuid,
          'system-uuid-system::transfer');
      // deposit/withdraw exist (for imports) but are hidden.
      expect(repo.categories(type: CategoryType.system).map((c) => c.tag),
          isNot(contains(SystemTag.deposit)));
      expect(repo.categories(type: CategoryType.system, includeHidden: true)
          .map((c) => c.tag), contains(SystemTag.deposit));
    });

    test('seeding twice does not duplicate', () {
      final before = repo.categories(includeHidden: true).length;
      repo.seedSystemCategories({});
      expect(repo.categories(includeHidden: true).length, before);
    });
  });

  group('balances', () {
    test('only confirmed, counted and past transactions count', () {
      repo.saveTransaction(_tx('a', 2500, Direction.income, category: 'salary'));
      repo.saveTransaction(_tx('b', 1000, Direction.expense));
      repo.saveTransaction(_tx('c', 999, Direction.expense, confirmed: false));
      repo.saveTransaction(_tx('d', 999, Direction.expense, counted: false));
      repo.saveTransaction(_tx('e', 999, Direction.expense,
          date: DateTime.now().add(const Duration(days: 3))));
      expect(repo.walletBalance('w1'), 10000 + 2500 - 1000);
    });

    test('total is per currency and respects count_in_total', () {
      repo.saveWallet(_wallet('hidden', start: 99999, counted: false));
      expect(repo.totalBalances(), {'EUR': 10000, 'USD': 500});
    });
  });

  group('categories', () {
    test('only one level of nesting', () {
      repo.saveCategory(_category('restaurant', CategoryType.expense, parent: 'food'));
      expect(
          () => repo.saveCategory(
              _category('pizza', CategoryType.expense, parent: 'restaurant')),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.categoryHierarchyNotSupported)));
    });

    test('a category with children cannot become a child', () {
      repo.saveCategory(_category('restaurant', CategoryType.expense, parent: 'food'));
      repo.saveCategory(_category('other', CategoryType.expense));
      expect(
          () => repo.saveCategory(
              _category('food', CategoryType.expense, parent: 'other')),
          throwsA(isA<RepositoryException>()));
    });

    test('child must have the type of the parent', () {
      expect(
          () => repo.saveCategory(
              _category('bonus', CategoryType.income, parent: 'food')),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.categoryNotConsistent)));
    });

    test('delete rules', () {
      repo.saveCategory(_category('restaurant', CategoryType.expense, parent: 'food'));
      expect(() => repo.deleteCategory('food'),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.categoryHasChildren)));
      repo.saveTransaction(_tx('t', 1, Direction.expense, category: 'restaurant'));
      expect(() => repo.deleteCategory('restaurant'),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.categoryInUse)));
      expect(() => repo.deleteCategory(SystemTag.uuidFor(SystemTag.transfer)),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.categorySystemReadOnly)));
      repo.deleteTransaction('t');
      repo.deleteCategory('restaurant');
      expect(repo.category('restaurant'), isNull);
    });

    test('changing the type of a parent updates its children', () {
      repo.saveCategory(_category('restaurant', CategoryType.expense, parent: 'food'));
      repo.saveCategory(_category('food', CategoryType.income));
      expect(repo.category('restaurant')!.type, CategoryType.income);
    });
  });

  group('transfers', () {
    test('creates two transactions plus fee', () {
      final id = repo.saveTransfer(TransferInput(
        fromWallet: 'w1',
        toWallet: 'w2',
        fromMoney: 3000,
        toMoney: 3000,
        taxMoney: 100,
        date: DateTime(2024, 1, 5),
        description: 'ATM',
        people: const [],
      ));
      expect(repo.walletBalance('w1'), 10000 - 3000 - 100);
      expect(repo.walletBalance('w2'), 3000);
      final view = repo.transferView(id)!;
      expect(view.taxMoney, 100);
      final tx = repo.transaction(view.transfer.from)!;
      expect(tx.type, TransactionType.transfer);
      expect(repo.category(tx.category)!.tag, SystemTag.transfer);
      expect(repo.category(repo.transaction(view.transfer.tax!)!.category)!.tag,
          SystemTag.transferTax);
    });

    test('update removes the fee and keeps transaction ids', () {
      final id = repo.saveTransfer(TransferInput(
          fromWallet: 'w1', toWallet: 'w2', fromMoney: 3000, toMoney: 3000,
          taxMoney: 100, date: DateTime(2024, 1, 5)));
      final before = repo.transfer(id)!;
      repo.saveTransfer(TransferInput(
          uuid: id, fromWallet: 'w1', toWallet: 'usd', fromMoney: 2000,
          toMoney: 2200, date: DateTime(2024, 1, 6)));
      final after = repo.transfer(id)!;
      expect(after.from, before.from);
      expect(after.tax, isNull);
      expect(repo.transaction(before.tax!), isNull);
      expect(repo.walletBalance('usd'), 500 + 2200);
      expect(repo.walletBalance('w2'), 0);
    });

    test('transfer transactions cannot be edited directly; deleting removes all', () {
      final id = repo.saveTransfer(TransferInput(
          fromWallet: 'w1', toWallet: 'w2', fromMoney: 1, toMoney: 1,
          taxMoney: 1, date: DateTime(2024, 1, 5)));
      final t = repo.transfer(id)!;
      expect(() => repo.saveTransaction(repo.transaction(t.from)!),
          throwsA(isA<RepositoryException>()));
      repo.deleteTransaction(t.to);
      expect(repo.transfer(id), isNull);
      expect(repo.transaction(t.from), isNull);
      expect(repo.transaction(t.tax!), isNull);
    });

    test('wallets used in transfers cannot be deleted', () {
      repo.saveTransfer(TransferInput(
          fromWallet: 'w1', toWallet: 'w2', fromMoney: 1, toMoney: 1,
          date: DateTime(2024, 1, 5)));
      expect(() => repo.deleteWallet('w2'),
          throwsA(predicate((e) =>
              e is RepositoryException &&
              e.error == RepositoryError.walletUsedInTransfer)));
    });

    test('same wallet is rejected', () {
      expect(
          () => repo.saveTransfer(TransferInput(
              fromWallet: 'w1', toWallet: 'w1', fromMoney: 1, toMoney: 1,
              date: DateTime(2024, 1, 5))),
          throwsA(isA<RepositoryException>()));
    });
  });

  group('debts', () {
    test('master transaction and payments', () {
      final debt = Debt(
        uuid: 'd',
        type: DebtType.debt,
        icon: _icon,
        description: 'Loan',
        date: DateTime(2024, 1, 1),
        wallet: 'w1',
        money: 5000,
      );
      repo.saveDebt(debt, createMasterTransaction: true);
      expect(repo.walletBalance('w1'), 15000);
      repo.saveTransaction(Transaction(
        uuid: 'pay',
        money: 2000,
        date: DateTime(2024, 1, 2),
        category: repo.debtPaymentCategory(DebtType.debt).uuid,
        direction: repo.debtPaymentDirection(DebtType.debt),
        type: TransactionType.debt,
        wallet: 'w1',
        debt: 'd',
      ));
      final view = repo.debtView('d')!;
      expect(view.paid, 2000);
      expect(view.remaining, 3000);
      expect(view.progress, closeTo(.4, 1e-9));
      expect(repo.walletBalance('w1'), 13000);
      repo.deleteDebt('d');
      expect(repo.walletBalance('w1'), 10000);
    });

    test('credits are expenses, receiving is income', () {
      repo.saveDebt(
          Debt(uuid: 'c', type: DebtType.credit, icon: _icon,
              description: 'Lent', date: DateTime(2024, 1, 1), wallet: 'w1',
              money: 1000),
          createMasterTransaction: true);
      expect(repo.walletBalance('w1'), 9000);
      expect(repo.debtPaymentDirection(DebtType.credit), Direction.income);
    });
  });

  group('transaction queries', () {
    setUp(() {
      repo.saveCategory(_category('restaurant', CategoryType.expense, parent: 'food'));
      repo.savePerson(const Person(uuid: 'anna', name: 'Anna', icon: _icon));
      repo.saveTransaction(
          _tx('t1', 1200, Direction.expense, category: 'restaurant')
              .copyForTest(description: 'Pizza Margherita'),
          people: ['anna']);
      repo.saveTransaction(_tx('t2', 300, Direction.expense, wallet: 'w2',
          date: DateTime(2024, 2, 1)));
      repo.saveTransaction(_tx('t3', 300, Direction.expense, wallet: 'usd'));
    });

    test('category filter includes sub categories', () {
      expect(repo.transactions(const TransactionFilter(category: 'food'))
          .map((v) => v.transaction.uuid).toSet(), {'t1', 't2', 't3'});
      expect(repo.transactions(const TransactionFilter(category: 'restaurant'))
          .map((v) => v.transaction.uuid), ['t1']);
    });

    test('wallet, person, date and text filters', () {
      expect(repo.transactions(const TransactionFilter(wallet: 'w2'))
          .single.transaction.uuid, 't2');
      expect(repo.transactions(const TransactionFilter(person: 'anna'))
          .single.transaction.uuid, 't1');
      expect(repo.transactionPeople('t1'), ['anna']);
      expect(repo.transactions(TransactionFilter(start: DateTime(2024, 1, 15)))
          .single.transaction.uuid, 't2');
      expect(repo.transactions(const TransactionFilter(query: 'margh'))
          .single.transaction.uuid, 't1');
      expect(repo.transactions(const TransactionFilter(query: '100%')), isEmpty);
      expect(
          repo.transactions(const TransactionFilter(
              query: 'pizza', searchFields: [SearchField.note])),
          isEmpty);
    });
  });

  group('recurrences', () {
    test('creates past occurrences immediately and the next date', () {
      final service = RecurrenceService(repo);
      service.saveRecurrentTransaction(
        RecurrentTransaction(
          uuid: 'rent',
          money: 80000,
          category: 'food',
          direction: Direction.expense,
          wallet: 'w1',
          startDate: DateTime(2024, 1, 1),
          lastOccurrence: DateTime(2024, 1, 1),
          rule: 'FREQ=MONTHLY;BYMONTHDAY=1',
        ),
        now: DateTime(2024, 3, 15),
      );
      final created = repo.transactions(const TransactionFilter())
          .where((v) => v.transaction.recurrence == 'rent')
          .map((v) => v.transaction.uuid)
          .toList();
      expect(created.toSet(),
          {'rent:2024-01-01', 'rent:2024-02-01', 'rent:2024-03-01'});
      final r = repo.recurrentTransaction('rent')!;
      expect(r.lastOccurrence, DateTime(2024, 3, 1));
      expect(r.nextOccurrence, DateTime(2024, 4, 1));

      // Processing later only adds the new occurrences and is idempotent.
      expect(service.processDue(now: DateTime(2024, 5, 2)), 2);
      expect(service.processDue(now: DateTime(2024, 5, 2)), 0);
      expect(repo.recurrentTransaction('rent')!.nextOccurrence,
          DateTime(2024, 6, 1));
    });

    test('COUNT finishes the recurrence', () {
      final service = RecurrenceService(repo);
      service.saveRecurrentTransaction(
        RecurrentTransaction(
          uuid: 'r',
          money: 1,
          category: 'food',
          direction: Direction.expense,
          wallet: 'w1',
          startDate: DateTime(2024, 1, 1),
          lastOccurrence: DateTime(2024, 1, 1),
          rule: 'FREQ=WEEKLY;COUNT=3',
        ),
        now: DateTime(2024, 1, 2),
      );
      service.processDue(now: DateTime(2024, 12, 31));
      expect(repo.recurrentTransaction('r')!.nextOccurrence, isNull);
      expect(repo.transactions(const TransactionFilter())
          .where((v) => v.transaction.recurrence == 'r'), hasLength(3));
    });

    test('future start creates nothing yet', () {
      final service = RecurrenceService(repo);
      service.saveRecurrentTransaction(
        RecurrentTransaction(
          uuid: 'f',
          money: 1,
          category: 'food',
          direction: Direction.expense,
          wallet: 'w1',
          startDate: DateTime(2030, 1, 1),
          lastOccurrence: DateTime(2030, 1, 1),
          rule: 'FREQ=DAILY',
        ),
        now: DateTime(2024, 1, 1),
      );
      expect(repo.recurrentTransaction('f')!.nextOccurrence, DateTime(2030, 1, 1));
      expect(repo.transaction('f:2030-01-01'), isNull);
    });

    test('recurrent transfers generate transfers', () {
      final service = RecurrenceService(repo);
      service.saveRecurrentTransfer(
        RecurrentTransfer(
          uuid: 'rt',
          fromWallet: 'w1',
          toWallet: 'w2',
          fromMoney: 100,
          toMoney: 100,
          taxMoney: 5,
          startDate: DateTime(2024, 1, 1),
          lastOccurrence: DateTime(2024, 1, 1),
          rule: 'FREQ=DAILY;COUNT=2',
        ),
        now: DateTime(2024, 1, 10),
      );
      expect(repo.transfer('rt:2024-01-01')!.recurrence, 'rt');
      expect(repo.transfer('rt:2024-01-02'), isNotNull);
      expect(repo.walletBalance('w2'), 200);
      expect(repo.walletBalance('w1'), 10000 - 210);
    });

    test('invalid rules are rejected', () {
      expect(
          () => RecurrenceService(repo).saveRecurrentTransaction(
              RecurrentTransaction(
                uuid: 'x', money: 1, category: 'food',
                direction: Direction.expense, wallet: 'w1',
                startDate: DateTime(2024), lastOccurrence: DateTime(2024),
                rule: 'nonsense')),
          throwsA(isA<RepositoryException>()));
    });

    test('occurrence uuid format matches the original', () {
      expect(RecurrenceService.occurrenceUuid('abc', DateTime(2024, 2, 3, 10)),
          'abc:2024-02-03');
      expect(toSqlDate(DateTime(2024, 2, 3)), '2024-02-03');
    });
  });
}

extension on Transaction {
  Transaction copyForTest({String? description}) => Transaction(
        uuid: uuid,
        money: money,
        date: date,
        description: description ?? this.description,
        category: category,
        direction: direction,
        wallet: wallet,
      );
}
