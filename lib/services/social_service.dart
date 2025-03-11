import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/social_post.dart';
import 'package:elderly_care/models/comment_model.dart';

class SocialService {
  final _supabase = SupabaseConfig.supabase;
  static final DateTime _currentTime = DateTime.parse('2025-03-10 19:04:21');

  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  Stream<List<SocialPost>> getPostsStream() {
    try {
      return _supabase
          .from('social_posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .asyncMap((posts) async {
            final List<SocialPost> socialPosts = [];
            for (final post in posts) {
              try {
                // Get author details
                final authorData = await _supabase
                    .from('profiles')
                    .select()
                    .eq('username', post['username'])
                    .single();
                
                // Get likes count and check if user liked
                final likes = await _supabase
                    .from('post_likes')
                    .select('username')
                    .eq('post_id', post['id']);
                
                final bool isLiked = likes.any((like) => like['username'] == _currentUser);
                final int likesCount = likes.length;

                // Get comments count
                final comments = await _supabase
                    .from('post_comments')
                    .select('id')
                    .eq('post_id', post['id']);

                socialPosts.add(SocialPost.fromJson({
                  ...post,
                  'author_name': authorData['name'],
                  'author_avatar': authorData['avatar_url'] ?? 
                    'https://ui-avatars.com/api/?name=${authorData['name']}',
                  'likes_count': likesCount,
                  'comments_count': comments.length,
                  'is_liked': isLiked,
                }));
              } catch (e) {
                print('Error processing post ${post['id']}: $e');
              }
            }
            return socialPosts;
          });
    } catch (e) {
      print('Error in getPostsStream: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      // Check if the user already liked the post
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('username', _currentUser)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'username': _currentUser,
          'created_at': _currentTime.toIso8601String(),
        });
      } else {
        // Remove like
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('username', _currentUser);
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Stream<List<Comment>> getPostCommentsStream(String postId) {
    try {
      return _supabase
          .from('post_comments')
          .stream(primaryKey: ['id'])
          .eq('post_id', postId)
          .order('created_at')
          .asyncMap((comments) async {
            final List<Comment> commentsList = [];
            for (final comment in comments) {
              try {
                // Get author details
                final authorData = await _supabase
                    .from('profiles')
                    .select()
                    .eq('username', comment['username'])
                    .single();
                
                commentsList.add(Comment.fromJson({
                  ...comment,
                  'author_name': authorData['name'],
                  'author_avatar': authorData['avatar_url'] ?? 
                    'https://ui-avatars.com/api/?name=${authorData['name']}',
                }));
              } catch (e) {
                print('Error processing comment ${comment['id']}: $e');
              }
            }
            return commentsList;
          });
    } catch (e) {
      print('Error in getPostCommentsStream: $e');
      rethrow;
    }
  }

  Future<void> createPost(String content, {String? imageUrl}) async {
    try {
      await _supabase.from('social_posts').insert({
        'username': _currentUser,
        'content': content,
        'image_url': imageUrl,
        'created_at': _currentTime.toIso8601String(),
      });
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }


  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'username': _currentUser,
        'content': content,
        'created_at': _currentTime.toIso8601String(),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }
}