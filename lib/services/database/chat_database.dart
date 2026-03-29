import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/chat_message.dart';

class ChatDatabase {
  static final ChatDatabase instance = ChatDatabase._init();
  static Database? _database;

  ChatDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assistant_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        reasoning TEXT
      )
    ''');
  }

  Future<void> saveMessage(String assistantId, ChatMessage message) async {
    final db = await instance.database;
    await db.insert('chat_messages', {
      'assistant_id': assistantId,
      'role': message.role,
      'content': message.text,
      'timestamp': message.time.toIso8601String(),
      'reasoning': message.reasoning,
    });
  }

  Future<List<ChatMessage>> getMessages(String assistantId) async {
    final db = await instance.database;
    final maps = await db.query(
      'chat_messages',
      where: 'assistant_id = ?',
      whereArgs: [assistantId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage(
        text: maps[i]['content'] as String,
        role: maps[i]['role'] as String,
        isMe: maps[i]['role'] == 'user',
        time: DateTime.parse(maps[i]['timestamp'] as String),
        reasoning: maps[i]['reasoning'] as String?,
      );
    });
  }

  Future<void> clearHistory(String assistantId) async {
    final db = await instance.database;
    await db.delete(
      'chat_messages',
      where: 'assistant_id = ?',
      whereArgs: [assistantId],
    );
  }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final db = await instance.database;
    // Get unique assistant_ids with their last message and timestamp
    return await db.rawQuery('''
      SELECT assistant_id, content, timestamp 
      FROM chat_messages 
      WHERE id IN (SELECT MAX(id) FROM chat_messages GROUP BY assistant_id)
      ORDER BY timestamp DESC
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) db.close();
  }
}
