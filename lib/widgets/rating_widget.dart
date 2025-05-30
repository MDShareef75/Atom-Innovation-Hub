import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rating_service.dart';
import '../models/rating.dart';

class RatingWidget extends StatefulWidget {
  final String appId;
  final String userId;

  const RatingWidget({
    Key? key,
    required this.appId,
    required this.userId,
  }) : super(key: key);

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  final _commentController = TextEditingController();
  double _currentRating = 0;
  bool _isSubmitting = false;
  bool _hasRated = false;
  double? _userRating;

  @override
  void initState() {
    super.initState();
    _checkIfUserRated();
  }

  Future<void> _checkIfUserRated() async {
    final rating = await RatingService().getUserRating(widget.appId, widget.userId);
    if (rating != null) {
      setState(() {
        _hasRated = true;
        _userRating = rating.rating;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rating = Rating(
        appId: widget.appId,
        userId: widget.userId,
        rating: _currentRating,
        comment: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await context.read<RatingService>().submitRating(rating);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
        _commentController.clear();
        setState(() => _currentRating = 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRated) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thank you for rating!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    _userRating?.toStringAsFixed(1) ?? '-',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate Our App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _currentRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 