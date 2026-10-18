#!/usr/bin/env sh
# Downloads the libraries used by the original MoneyWallet app for the
# backup interoperability test (test/interop_test.dart). Development only.
set -e
cd "$(dirname "$0")"
mkdir -p lib
fetch() {
  [ -f "lib/$2" ] || curl -fsSL -o "lib/$2" "https://repo1.maven.org/maven2/$1/$2"
}
fetch net/lingala/zip4j/zip4j/1.3.2 zip4j-1.3.2.jar
fetch com/google/code/gson/gson/2.10.1 gson-2.10.1.jar
fetch org/json/json/20231013 json-20231013.jar
echo "ok"
