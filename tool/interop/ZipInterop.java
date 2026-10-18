import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;

import net.lingala.zip4j.core.ZipFile;
import net.lingala.zip4j.io.ZipInputStream;
import net.lingala.zip4j.model.FileHeader;
import net.lingala.zip4j.model.ZipParameters;
import net.lingala.zip4j.util.Zip4jConstants;

import org.json.JSONObject;

import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

/**
 * Re-implementation of the backup import/export code paths of the original
 * MoneyWallet app (DefaultBackupExporter, DefaultBackupImporter and
 * JSONDataStreamReader) using the very same libraries (zip4j 1.3.2,
 * org.json and a JsonReader with the android.util.JsonReader API).
 *
 * Usage:
 *   read  <backup> <password|-> <attachmentDir>
 *   write <backup> <password|-> <database.json> [attachment files...]
 */
public class ZipInterop {

    private static final String[] SECTIONS = {
        "currencies", "wallets", "categories", "events", "places", "people",
        "event_people", "debts", "debt_people", "budgets", "budget_wallets",
        "savings", "recurrent_transactions", "recurrent_transfers",
        "transactions", "transaction_people", "transaction_models",
        "transfers", "transfer_people", "transfer_models", "attachments",
        "transaction_attachment", "transfer_attachment",
    };

    public static void main(String[] args) throws Exception {
        String password = "-".equals(args[2]) ? null : args[2];
        if ("read".equals(args[0])) {
            read(new File(args[1]), password, new File(args[3]));
        } else {
            File[] attachments = new File[args.length - 4];
            for (int i = 4; i < args.length; i++) {
                attachments[i - 4] = new File(args[i]);
            }
            write(new File(args[1]), password, new File(args[3]), attachments);
        }
    }

    private static ZipParameters parameters(String root, String password) {
        ZipParameters parameters = new ZipParameters();
        parameters.setRootFolderInZip(root);
        parameters.setCompressionMethod(Zip4jConstants.COMP_DEFLATE);
        parameters.setCompressionLevel(Zip4jConstants.DEFLATE_LEVEL_NORMAL);
        if (password != null && !password.isEmpty()) {
            parameters.setEncryptFiles(true);
            parameters.setEncryptionMethod(Zip4jConstants.ENC_METHOD_AES);
            parameters.setAesKeyStrength(Zip4jConstants.AES_STRENGTH_256);
            parameters.setPassword(password);
        }
        return parameters;
    }

    private static void write(File backup, String password, File json, File[] attachments) throws Exception {
        File temp = Files.createTempDirectory("mw").toFile();
        File database = new File(temp, "database.json");
        Files.copy(json.toPath(), database.toPath(), StandardCopyOption.REPLACE_EXISTING);
        ZipFile zipFile = new ZipFile(backup);
        zipFile.addFile(database, parameters("databases/", password));
        if (attachments.length > 0) {
            ZipParameters zipParameters = parameters("attachments/", password);
            for (File attachment : attachments) {
                zipFile.addFile(attachment, zipParameters);
            }
        }
        System.out.println("OK");
    }

    private static void read(File backup, String password, File attachmentDir) throws Exception {
        ZipFile zipFile = new ZipFile(backup);
        if (!zipFile.isValidZipFile()) throw new IllegalStateException("not a zip file");
        FileHeader header = zipFile.getFileHeader("databases/database.json");
        if (header == null) throw new IllegalStateException("database file not found");
        if (header.isEncrypted()) {
            if (password == null) throw new IllegalStateException("missing user password");
            header.setPassword(password.toCharArray());
        }
        ZipInputStream inputStream = zipFile.getInputStream(header);
        JsonReader reader = new JsonReader(new InputStreamReader(inputStream));
        reader.beginObject();
        if (!"header".equals(reader.nextName())) throw new IllegalStateException("missing header");
        int version = readObject(reader).getInt("version_code");
        StringBuilder result = new StringBuilder("version=" + version);
        for (String section : SECTIONS) {
            if (version < 2 && "currencies".equals(section)) continue;
            String name = reader.nextName();
            if (!section.equals(name)) {
                throw new IllegalStateException("Wrong array name (expected = '" + section + "', found = '" + name + "')");
            }
            reader.beginArray();
            int count = 0;
            while (reader.peek() != JsonToken.END_ARRAY) {
                JSONObject object = readObject(reader);
                if (object.has("deleted") && object.optBoolean("deleted", true)) {
                    throw new IllegalStateException("deleted row exported");
                }
                count++;
            }
            reader.endArray();
            result.append(' ').append(section).append('=').append(count);
        }
        reader.close();

        for (Object obj : zipFile.getFileHeaders()) {
            FileHeader fileHeader = (FileHeader) obj;
            if (fileHeader.isEncrypted()) fileHeader.setPassword(password.toCharArray());
            String path = fileHeader.getFileName();
            if (path.startsWith("attachments/")) {
                String name = path.substring("attachments/".length());
                if (!name.contains("/")) {
                    zipFile.extractFile(fileHeader, attachmentDir.getPath(), null, name);
                }
            }
        }
        System.out.println(result);
    }

    /** Copy of JSONDataStreamReader.readObject() of the original app. */
    private static JSONObject readObject(JsonReader reader) throws Exception {
        reader.beginObject();
        JSONObject object = new JSONObject();
        while (reader.peek() != JsonToken.END_OBJECT) {
            String name = reader.nextName();
            switch (reader.peek()) {
                case STRING:
                    object.put(name, reader.nextString());
                    break;
                case NUMBER:
                    String value = reader.nextString();
                    try {object.put(name, Long.parseLong(value));} catch (NumberFormatException ignore) {}
                    try {object.put(name, Double.parseDouble(value));} catch (NumberFormatException ignore) {}
                    break;
                case BOOLEAN:
                    object.put(name, reader.nextBoolean());
                    break;
                default:
                    // The original would loop forever on null / nested values.
                    throw new IllegalStateException("Unsupported token for '" + name + "': " + reader.peek());
            }
        }
        reader.endObject();
        return object;
    }
}
