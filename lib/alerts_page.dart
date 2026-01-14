import 'package:flutter/material.dart';
import 'services/alert_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Alert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    
    final alerts = await AlertService.getAlerts();
    
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _generateAlerts() async {
    final success = await AlertService.generateAlerts();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wygenerowano nowe alerty!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAlerts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd podczas generowania alertów'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Powiadomienia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Odśwież',
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: _generateAlerts,
            tooltip: 'Wygeneruj alerty',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Brak powiadomień',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        itemCount: _alerts.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final isLowStock = alert.type == 'LOW_STOCK';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: alert.read ? null : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? Colors.orange[100] : Colors.blue[100],
          child: Icon(
            isLowStock ? Icons.warning : Icons.info,
            color: isLowStock ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(
          alert.message,
          style: TextStyle(
            fontWeight: alert.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typ: ${_getTypeLabel(alert.type)}'),
            Text(_formatTimestamp(alert.timestamp)),
          ],
        ),
        trailing: alert.read
            ? const Icon(Icons.check, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => _markAsRead(alert),
                tooltip: 'Oznacz jako przeczytane',
              ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'LOW_STOCK':
        return 'Niski stan';
      default:
        return type;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} dni temu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} godzin temu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minut temu';
    } else {
      return 'Przed chwilą';
    }
  }

  Future<void> _markAsRead(Alert alert) async {
    final success = await AlertService.markAsRead(alert.id);
    
    if (success) {
      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = Alert(
            id: alert.id,
            type: alert.type,
            message: alert.message,
            timestamp: alert.timestamp,
            read: true,
          );
        }
      });
    }
  }
}