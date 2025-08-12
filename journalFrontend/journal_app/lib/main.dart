import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Base URL for the API
const String baseUrl = 'https://journal-xr5m.onrender.com';

// Function to construct API URLs correctly
String getApiUrl(String endpoint) {
  endpoint = endpoint.replaceAll(RegExp(r'^/+'), '');
  return '$baseUrl/api/$endpoint';
}

void main() => runApp(JournalApp());

class JournalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      debugShowCheckedModeBanner: false,
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
        Uri.parse(getApiUrl('entries')),
        headers: {'Content-Type': 'application/json'},
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
        Uri.parse(getApiUrl('entries')),
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
            Hero(
              tag: 'journal_card',
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _tabController.animateTo(1),
                            tooltip: 'Select date',
                          ),
                        ],
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
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          // Trigger rebuild to update character count
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_textController.text.length} characters',
                          style: TextStyle(
                            color: _textController.text.length > 0 
                              ? Colors.grey[600] 
                              : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                key: ValueKey(_isLoading),
                onPressed: _textController.text.trim().isEmpty || _isLoading 
                  ? null 
                  : submitEntry,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textController.text.trim().isEmpty
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _moodDescriptions.entries.map((entry) {
        final isSelected = _selectedMood == entry.key;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedMood = entry.key),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 24),
                  ),
                  AnimatedSize(
                    duration: Duration(milliseconds: 200),
                    child: SizedBox(
                      width: isSelected ? 8 : 0,
                    ),
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: Duration(milliseconds: 200),
                      child: isSelected
                          ? Text(
                              entry.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
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
          currentDay: DateTime.now(),
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDate, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              // Update focusedDay when selecting a day
              _tabController.animateTo(0); // Switch to write tab when selecting a date
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
            weekendTextStyle: TextStyle(color: Colors.red),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No journal entries yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: Icon(Icons.add),
                        label: Text('Write your first entry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                            DateTime.parse(entry['date'] ?? DateTime.now().toIso8601String()),
                          ),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          entry['text'] ?? 'No content',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Show full entry in a dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Text(entry['mood'] ?? '😊', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(
                                      DateTime.parse(entry['date'] ?? DateTime.now().toIso8601String()),
                                    ),
                                  ),
                                ],
                              ),
                              content: SingleChildScrollView(
                                child: Text(entry['text'] ?? 'No content'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
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
