import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(JournalApp());

class JournalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: JournalEntryPage(),
    );
  }
}

class JournalEntryPage extends StatefulWidget {
  @override
  _JournalEntryPageState createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  String _selectedMood = '😊';
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _entries = [];
  final Map<String, String> _moodDescriptions = {
    '😊': 'Happy',
    '😢': 'Sad',
    '😠': 'Angry',
    '😴': 'Tired',
    '😎': 'Cool',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/entries'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _entries = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error fetching entries: $e');
    }
  }

  Future<void> submitEntry() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write something in your journal')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/entries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'text': _textController.text,
          'mood': _selectedMood,
        }),
      );

      if (response.statusCode == 201) {
        _textController.clear();
        await _fetchEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal entry saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to save entry');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving entry'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Journal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.edit), text: 'Write'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWriteTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildWriteTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildMoodSelector(),
                    SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'How was your day?',
                        prefixIcon: Icon(Icons.edit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : submitEntry,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 8,
      children: _moodDescriptions.entries.map((entry) {
        final isSelected = _selectedMood == entry.key;
        return InkWell(
          onTap: () => setState(() => _selectedMood = entry.key),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: TextStyle(fontSize: 24)),
                if (isSelected) ...[
                  SizedBox(width: 8),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDate, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
            });
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    entry['mood'] ?? '😊',
                    style: TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    DateFormat('MMM d, yyyy').format(
                      DateTime.parse(entry['date']),
                    ),
                  ),
                  subtitle: Text(
                    entry['text'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
