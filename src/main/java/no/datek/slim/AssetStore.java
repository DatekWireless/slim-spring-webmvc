package no.datek.slim;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

public class AssetStore {
    public static final Map<String, String> assetPaths = new ConcurrentHashMap<>();

    // Used in views with `asset_path`.
    public static String getHashedPath(String path) throws IOException, NoSuchAlgorithmException {
        return "/assets/" + getHashedName(path);
    }

    public static String getFile(String hashedName) {
        return System.getProperty("java.io.tmpdir") + "/assets/" + hashedName;
    }

    private static String getHashedName(String path) throws IOException, NoSuchAlgorithmException {
        path = getNormalizedPath(path);
        String hashedName = assetPaths.get(path);
        if (hashedName == null) {
            byte[] bytes = readAssetBytes(path);
            hashedName = getHashedName(path, bytes);
            String activeProfiles = System.getProperty("spring.profiles.active");
            if (activeProfiles == null || !activeProfiles.contains("development")) {
                assetPaths.put(path, hashedName);
            }
            storeFile(hashedName, bytes);
        }
        return hashedName;
    }

    private static String getHashedName(String path, byte[] bytes) throws NoSuchAlgorithmException {
        String[] dotParts = path.split("\\.");
        String prefix = String.join(".", Arrays.copyOfRange(dotParts, 0, dotParts.length - 1));
        String checksum = new BigInteger(1, MessageDigest.getInstance("MD5").digest(bytes)).toString(16);
        String suffix = dotParts[dotParts.length - 1];
        return prefix + "-" + checksum + "." + suffix;
    }

    private static byte[] readAssetBytes(String path) throws IOException {
        try (InputStream assetStream = AssetStore.class.getClassLoader().getResourceAsStream("static/" + path)) {
            if (assetStream == null) {
                throw new FileNotFoundException(path);
            }
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(assetStream))) {
                return reader.lines().collect(Collectors.joining("\n")).getBytes(StandardCharsets.UTF_8);
            }
        }
    }

    private synchronized static void storeFile(String hashedName, byte[] bytes) throws IOException {
        Path file = Path.of(getFile(hashedName));
        if (!Files.exists(file)) {
            if (!Files.exists(file.getParent())) {
                Files.createDirectories(file.getParent());
            }
            Path hashedFile = Files.createFile(file);
            Files.write(hashedFile, bytes);
        }
    }

    private static String getNormalizedPath(String path) {
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        return path;
    }
}
