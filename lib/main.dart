import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CardMatchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Match',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CardMatch(title: 'Card Match'),
    );
  }
}

class CardMatch extends StatefulWidget {
  const CardMatch({super.key, required this.title});

  final String title;

  @override
  State<CardMatch> createState() => _CardMatchState();
}

class CardMatchProvider extends ChangeNotifier {
  List<String> cards = <String>['ace_of_hearts.png', 'jack_of_hearts.png', 'queen_of_hearts.png', 
  'king_of_hearts.png', 'ace_of_spades.png', 'jack_of_spades.png', 'queen_of_spades.png', 'king_of_spades.png', 
  'ace_of_hearts.png', 'jack_of_hearts.png', 'queen_of_hearts.png', 'king_of_hearts.png', 
  'ace_of_spades.png', 'jack_of_spades.png', 'queen_of_spades.png', 'king_of_spades.png'];
  List<String> randomCards = <String>[];
  late Map<int, bool> flippedCards;
  bool isProcessing = false;
  int flipCounter = 1;
  int savedIndex = 0;
  int matches = 0;

  void shuffleCards() {
    randomCards = cards;
    randomCards.shuffle();
    flippedCards = {for (int i = 0; i < randomCards.length; i++) i: false};
    notifyListeners();
  }

    void checkMatch(int index) {
    if (flipCounter == 2) {
      if(index != savedIndex && randomCards[index] == randomCards[savedIndex]) {
        flipCounter = 1;
        matches++;
        notifyListeners();
      } else {
        isProcessing = true;
        notifyListeners();
        Future.delayed(Duration(seconds: 1), () {
          flippedCards[index] = false;
          flippedCards[savedIndex] = false;
          flipCounter = 1;
          isProcessing = false;
          notifyListeners();
        });
      }
    } else if (flipCounter == 1) {
      savedIndex = index;
      flipCounter++;
      notifyListeners();
    }
  }

  void flipCard(int index) {
    if (isProcessing) return;
    flippedCards[index] = !(flippedCards[index] ?? false);
    checkMatch(index);
    notifyListeners();
  }

}


class FlipCardItem extends StatefulWidget {
  final int index;
  final String frontImage;
  final bool isFlipped;
  final VoidCallback onFlip;

  const FlipCardItem({
    super.key,
    required this.index,
    required this.frontImage,
    required this.isFlipped,
    required this.onFlip,
  });

  @override
  State<FlipCardItem> createState() => _FlipCardItemState();
}

class _FlipCardItemState extends State<FlipCardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          if (!widget.isFlipped) {
            setState(() => _showFront = true);
          }
        }
      });
  }

  @override
  void didUpdateWidget(FlipCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
        setState(() => _showFront = false);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardMatchProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (!widget.isFlipped && !_controller.isAnimating && !provider.isProcessing) {
          provider.flipCard(widget.index);
          widget.onFlip();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    _showFront 
                      ? 'assets/images/card_back.png'
                      : widget.frontImage
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class _CardMatchState extends State<CardMatch> with SingleTickerProviderStateMixin{

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CardMatchProvider>(context, listen: false).shuffleCards();
    });
  }

  void showWin(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You won!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardMatchProvider = Provider.of<CardMatchProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: cardMatchProvider.randomCards.length,
        itemBuilder: (context, index) {
          return FlipCardItem(
            index: index,
            frontImage: 'assets/images/${cardMatchProvider.randomCards[index]}',
            isFlipped: cardMatchProvider.flippedCards[index] ?? false,
            onFlip: () {
              if (cardMatchProvider.matches == 8) {
                showWin(context);
              }
            },
          );
        }),
      );
  }
}
