import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'notification_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _pendingInvitationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingInvitationsCount();
  }

  Future<void> _loadPendingInvitationsCount() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        final count = await NotificationService.getPendingInvitationsCount(
          authProvider.currentUser!.username,
        );
        setState(() {
          _pendingInvitationsCount = count;
        });
      } catch (e) {
        // Falhar silenciosamente
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Usuário não encontrado'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 20),
                
                // Nome do usuário
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do Perfil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nome de usuário
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nome de usuário',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Data de criação
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Membro desde',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(user.createdAt),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (user.updatedAt != null) ...[
                          const SizedBox(height: 16),
                          
                          // Última atualização
                          Row(
                            children: [
                              const Icon(Icons.update, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Última atualização',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(user.updatedAt!),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Opções
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.blue),
                        title: const Text('Alterar Senha'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showChangePasswordDialog(context, authProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Sair'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showLogoutDialog(context, authProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications, color: Colors.blue),
                        title: const Text('Notificações'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_pendingInvitationsCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _pendingInvitationsCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                        onTap: () => _openNotificationPage(context, authProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool obscureCurrentPassword = true;
        bool obscureNewPassword = true;
        bool obscureConfirmPassword = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Alterar Senha'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Senha atual
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Senha atual',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrentPassword = !obscureCurrentPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite sua senha atual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Nova senha
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite uma nova senha';
                          }
                          if (value.length < 4) {
                            return 'A senha deve ter pelo menos 4 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirmar nova senha
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nova senha',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme a nova senha';
                          }
                          if (value != newPasswordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : () async {
                        if (formKey.currentState!.validate()) {
                          final success = await auth.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          
                          if (context.mounted) {
                            if (success) {
                              currentPasswordController.dispose();
                              newPasswordController.dispose();
                              confirmPasswordController.dispose();
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Senha alterada com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(auth.errorMessage ?? 'Erro ao alterar senha'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Alterar'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openNotificationPage(BuildContext context, AuthProvider authProvider) async {
    // Navegar para a página de notificações
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationPage(authProvider: authProvider),
      ),
    );
    
    // Recarregar contagem de convites pendentes quando voltar
    _loadPendingInvitationsCount();
  }
}