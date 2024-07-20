import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      routes: {
        '/planlama': (context) => const PlanlamaPage(),
        '/sohbet': (context) => const SohbetPage(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF81D4FA), // Açık mavi
              Color(0xFF0288D1), // Daha koyu mavi
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/planlama');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('Plan'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sohbet');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('Sohbet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanlamaPage extends StatefulWidget {
  const PlanlamaPage({super.key});

  @override
  _PlanlamaPageState createState() => _PlanlamaPageState();
}

class _PlanlamaPageState extends State<PlanlamaPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  Future<void> _sendQuery() async {
    final query = _controller.text;
    if (query.isNotEmpty) {
      setState(() {
        _messages.add(Message(text: query, isUser: true));
        _isTyping = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://573a-35-185-231-208.ngrok-free.app/predict'), // Ngrok URL'sini buraya yerleştirin
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'input_text': query}),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          setState(() {
            _messages.add(Message(text: jsonResponse['output_text'], isUser: false));
            _isTyping = false;
          });
        } else {
          setState(() {
            _messages.add(Message(text: 'Error retrieving response.', isUser: false));
            _isTyping = false;
          });
        }
      } catch (e) {
        setState(() {
          _messages.add(Message(text: 'Failed to send request.', isUser: false));
          _isTyping = false;
        });
      }

      _controller.clear(); // Mesaj alanını temizle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planlama'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const AnimatedDots();
                }
                final message = _messages[index];
                return MessageBubble(
                  text: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedDots(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı girin',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SohbetPage extends StatefulWidget {
  const SohbetPage({super.key});

  @override
  _SohbetPageState createState() => _SohbetPageState();
}

class _SohbetPageState extends State<SohbetPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  Future<void> _sendQuery() async {
    final query = _controller.text;
    if (query.isNotEmpty) {
      print('Sending query: $query');  // Kullanıcı sorgusunu gönderme logu
      setState(() {
        _messages.add(Message(text: query, isUser: true));
        _isTyping = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/cevapla'), // Güncellenmiş LAN IP adresi
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'soru': query}),
        );

        print('Received status code: ${response.statusCode}'); // HTTP durum kodu logu

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          print('Received response: ${jsonResponse['cevap']}'); // API'den alınan yanıtı loglama
          setState(() {
            _messages.add(Message(text: jsonResponse['cevap'], isUser: false));
            _isTyping = false;
          });
        } else {
          print('Error response body: ${response.body}'); // Hata yanıtını loglama
          setState(() {
            _messages.add(Message(text: 'Error retrieving response.', isUser: false));
            _isTyping = false;
          });
        }
      } catch (e) {
        print('Failed to send request: $e'); // İstek gönderme hatasını loglama
        setState(() {
          _messages.add(Message(text: 'Failed to send request.', isUser: false));
          _isTyping = false;
        });
      }

      _controller.clear(); // Mesaj alanını temizle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const AnimatedDots();
                }
                final message = _messages[index];
                return MessageBubble(
                  text: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedDots(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your query',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : const Color(0xFFF5F5DC),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // Gölgenin y ekseninde kayması
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AnimatedDots extends StatefulWidget {
  const AnimatedDots({super.key});

  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Opacity(
                opacity: _controller!.value > index / 3 ? 1.0 : 0.0,
                child: const Text(
                  '.',
                  style: TextStyle(fontSize: 30, color: Colors.grey),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}