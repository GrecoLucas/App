import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../utils/app_theme.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  final Widget child;

  const ConnectivityStatusWidget({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  bool _showingOfflineBanner = false;

  @override
  void initState() {
    super.initState();
    ConnectivityService.addListener(_onConnectivityChanged);
    _checkInitialStatus();
  }

  @override
  void dispose() {
    ConnectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _checkInitialStatus() {
    if (!ConnectivityService.isOnline && !_showingOfflineBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflineBanner();
      });
    }
  }

  void _onConnectivityChanged() {
    if (mounted) {
      if (!ConnectivityService.isOnline && !_showingOfflineBanner) {
        _showOfflineBanner();
      } else if (ConnectivityService.isOnline && _showingOfflineBanner) {
        _hideOfflineBanner();
        _showOnlineBanner();
      }
    }
  }

  void _showOfflineBanner() {
    if (!mounted) return;
    
    setState(() {
      _showingOfflineBanner = true;
    });

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppTheme.warningRed,
        content: Row(
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sem conexão com a internet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Você não pode acessar listas compartilhadas offline',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              setState(() {
                _showingOfflineBanner = false;
              });
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _hideOfflineBanner() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    setState(() {
      _showingOfflineBanner = false;
    });
  }

  void _showOnlineBanner() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryGreen,
        content: const Row(
          children: [
            Icon(
              Icons.wifi,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Conectado! Sincronizando listas...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class OfflineListIndicator extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onTap;

  const OfflineListIndicator({
    super.key,
    required this.isOffline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedListBlockedIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const SharedListBlockedIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.share_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'Lista compartilhada indisponível',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta lista está compartilhada e não pode ser acessada offline. '
              'Conecte-se à internet para ver e editar esta lista.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Sem conexão',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
