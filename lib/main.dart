import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main entry point for the application
void main() async {
  // Load environment variables from the .env file
  await dotenv.load(fileName: ".env");
  // Run the Flutter application
  runApp(MyApp());
}

// StatelessWidget representing the main application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Flutter',
      // Define the theme of the application, using a dark mode color scheme
      theme: ThemeData.dark().copyWith(
        primaryColor: Color.fromARGB(255, 86, 112, 125),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color.fromARGB(255, 90, 108, 138)),
        scaffoldBackgroundColor: Color.fromARGB(255, 105, 105, 105),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatScreen(),
    );
  }
}

// StatefulWidget representing the chat screen
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controller to manage the input text field
  final TextEditingController _controller = TextEditingController();
  // List to store messages in the chat
  List<Map<String, String>> _messages = [];

  // Function to handle sending a message
  Future<void> _sendMessage(String message) async {
    // Add the user's message to the list and clear the input field
    setState(() {
      _messages.add({"role": "You", "message": message});
    });
    _controller.clear();

    // Retrieve the API key from environment variables
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // Show an error message if the API key is not found
      setState(() {
        _messages.add({"role": "Error", "message": "API key not found"});
      });
      return;
    }

    try {
      // Make a POST request to the OpenAI API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response and add the ChatGPT's reply to the list
        final responseData = jsonDecode(response.body);
        final chatResponse = responseData['choices'][0]['message']['content'];
        setState(() {
          _messages.add({"role": "ChatGPT", "message": chatResponse});
        });
      } else {
        // Show an error message if the API call fails
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['error']['message'];
        print('Failed to fetch response: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _messages.add({"role": "Error", "message": "Error: $errorMessage"});
        });
      }
    } catch (e) {
      // Handle any exceptions that occur during the API call
      print('Error occurred: $e');
      setState(() {
        _messages.add({"role": "Error", "message": "Error occurred: $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with the title of the application
      appBar: AppBar(
        title: Text('Chat Flutter'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 122, 158, 176),
      ),
      body: Column(
        children: [
          // Expanded widget to display the list of messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['role'] == "You";
                return Align(
                  alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUserMessage ? const Color.fromARGB(255, 92, 145, 236) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['role']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUserMessage ? Colors.white : Colors.grey[300],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message['message']!,
                          style: TextStyle(
                            color: isUserMessage ? Colors.white : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input field and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Expanded widget to allow the input field to take up available space
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                // Floating action button to send the message
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                    }
                  },
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
