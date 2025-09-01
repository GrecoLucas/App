import '../models/list_invitation.dart';
import 'supabase_service.dart';

class NotificationService {
  
  /// Busca todos os convites pendentes para um usuário
  static Future<List<ListInvitation>> getUserInvitations(String username) async {
    try {
      final response = await SupabaseService.client
          .from('list_invitations')
          .select('''
            id,
            list_id,
            list_name,
            inviter_username,
            invited_username,
            created_at,
            status
          ''')
          .eq('invited_username', username)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response
          .map<ListInvitation>((json) => ListInvitation.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Erro ao carregar convites: $error');
    }
  }

  /// Aceita um convite de lista
  static Future<void> acceptInvitation(String invitationId, String listId, String username) async {
    try {
      print('Aceitando convite - ID: $invitationId, ListID: $listId, Username: $username');
      
      // Buscar ID do usuário primeiro para verificar se existe
      final userId = await _getUserIdByUsername(username);
      print('User ID encontrado: $userId');
      
      // Verificar se já existe compartilhamento
      final existingShare = await SupabaseService.client
          .from('shared_lists')
          .select('id')
          .eq('list_id', int.parse(listId))
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingShare != null) {
        print('Compartilhamento já existe, apenas atualizando status do convite');
      } else {
        // Adicionar usuário à lista compartilhada
        print('Adicionando usuário à lista compartilhada');
        await SupabaseService.client
            .from('shared_lists')
            .insert({
              'list_id': int.parse(listId),
              'user_id': userId,
              'permission': 'edit'
            });
        print('Usuário adicionado à lista compartilhada');
      }

      // Atualizar status do convite
      print('Atualizando status do convite para accepted');
      await SupabaseService.client
          .from('list_invitations')
          .update({'status': 'accepted'})
          .eq('id', invitationId);
      
      print('Convite aceito com sucesso');
    } catch (error) {
      print('Erro ao aceitar convite: $error');
      throw Exception('Erro ao aceitar convite: $error');
    }
  }

  /// Rejeita um convite de lista
  static Future<void> rejectInvitation(String invitationId) async {
    try {
      await SupabaseService.client
          .from('list_invitations')
          .update({'status': 'rejected'})
          .eq('id', invitationId);
    } catch (error) {
      throw Exception('Erro ao rejeitar convite: $error');
    }
  }

  /// Cria um novo convite para uma lista
  static Future<void> createInvitation({
    required String listId,
    required String listName,
    required String inviterUsername,
    required String invitedUsername,
  }) async {
    try {
      // Verificar se já existe um convite pendente
      final existingInvitation = await SupabaseService.client
          .from('list_invitations')
          .select('id')
          .eq('list_id', listId)
          .eq('invited_username', invitedUsername)
          .eq('status', 'pending');

      if (existingInvitation.isNotEmpty) {
        throw Exception('Já existe um convite pendente para este usuário');
      }

      // Criar novo convite
      await SupabaseService.client
          .from('list_invitations')
          .insert({
            'list_id': int.parse(listId),
            'list_name': listName,
            'inviter_username': inviterUsername,
            'invited_username': invitedUsername,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (error) {
      throw Exception('Erro ao criar convite: $error');
    }
  }

  /// Conta o número de convites pendentes para um usuário
  static Future<int> getPendingInvitationsCount(String username) async {
    try {
      final response = await SupabaseService.client
          .from('list_invitations')
          .select('id')
          .eq('invited_username', username)
          .eq('status', 'pending');

      return response.length;
    } catch (error) {
      return 0;
    }
  }

  /// Helper para buscar ID do usuário pelo username
  static Future<int> _getUserIdByUsername(String username) async {
    try {
      final response = await SupabaseService.client
          .from('Users')
          .select('id')
          .eq('Username', username)
          .single();

      return response['id'];
    } catch (error) {
      throw Exception('Usuário não encontrado: $error');
    }
  }
}
