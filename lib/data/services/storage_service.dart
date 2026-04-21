abstract class StorageService {
  // Write String
  Future<void> setString(String key, String value);

  // Read String
  Future<String?> getString(String key);

  // Write Integer
  Future<void> setInt(String key, int value);

  // Read Integer
  Future<int?> getInt(String key);

  // Write Boolean
  Future<void> setBool(String key, bool value);

  // Read Boolean
  Future<bool?> getBool(String key);

  // Write List
  Future<void> setList(String key, List<String> value);

  // Read List
  Future<List<String>?> getList(String key);

  // Write JSON
  Future<void> setJSON(String key, Map<String, dynamic> value);

  // Read JSON
  Future<Map<String, dynamic>?> getJSON(String key);

  // Remove
  Future<void> remove(String key);

  // Clear All
  Future<void> clear();

  // Contains Key
  Future<bool> containsKey(String key);

  // Get All Keys
  Future<List<String>> getAllKeys();
}

class StorageServiceImpl implements StorageService {
  // In-memory storage for mock implementation
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _storage[key] as String?;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _storage[key] = value;
  }

  @override
  Future<int?> getInt(String key) async {
    return _storage[key] as int?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _storage[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _storage[key] as bool?;
  }

  @override
  Future<void> setList(String key, List<String> value) async {
    _storage[key] = value;
  }

  @override
  Future<List<String>?> getList(String key) async {
    return _storage[key] as List<String>?;
  }

  @override
  Future<void> setJSON(String key, Map<String, dynamic> value) async {
    _storage[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJSON(String key) async {
    return _storage[key] as Map<String, dynamic>?;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _storage.keys.toList();
  }
}
