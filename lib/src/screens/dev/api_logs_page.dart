import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trydos_wallet/src/api/api_log.dart';

/// In-app network inspector. Lists every captured API request as a card and
/// opens a details page on tap. Reached via a long-press on the Settings tab.
class ApiLogsPage extends StatelessWidget {
  const ApiLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F5),
      appBar: AppBar(
        title: const Text('API Logs'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1D1D1D),
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: () => ApiLogStore.instance.clear(),
            icon: const Icon(Icons.delete_outline, color: Color(0xffFF5F61)),
            label: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xffFF5F61)),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ApiLogEntry>>(
        valueListenable: ApiLogStore.instance.listenable,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No requests logged yet',
                style: TextStyle(color: Color(0xff8D8D8D)),
              ),
            );
          }
          // Newest first.
          final sorted = [...entries]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _LogCard(entry: sorted[index]),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry});

  final ApiLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ApiLogDetailsPage(entry: entry)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _MethodBadge(method: entry.method),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1D1D1D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_time(entry.timestamp)} · ${entry.durationMs}ms',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff8D8D8D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(entry: entry),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = methodColor(method);
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.entry});

  final ApiLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isError = entry.isError;
    final color = isError ? const Color(0xffFF5F61) : const Color(0xff34D317);
    final label = entry.statusCode?.toString() ?? (isError ? 'ERR' : '—');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Request details: method, url, headers, query, body and response.
class ApiLogDetailsPage extends StatelessWidget {
  const ApiLogDetailsPage({super.key, required this.entry});

  final ApiLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F5),
      appBar: AppBar(
        title: Text('${entry.method} ${entry.statusCode ?? ''}'.trim()),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1D1D1D),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Section(
            title: 'URL',
            child: _CopyableText(text: entry.url),
          ),
          if (entry.errorMessage != null)
            _Section(
              title: 'Error',
              child: Text(
                entry.errorMessage!,
                style: const TextStyle(
                  color: Color(0xffFF5F61),
                  fontSize: 13,
                ),
              ),
            ),
          _Section(
            title: 'Request Headers',
            child: _KeyValueBlock(map: entry.requestHeaders),
          ),
          if (entry.queryParameters.isNotEmpty)
            _Section(
              title: 'Query Parameters',
              child: _KeyValueBlock(map: entry.queryParameters),
            ),
          _Section(
            title: 'Request Body',
            child: _CopyableText(
              text: entry.requestBody.isEmpty ? '—' : entry.requestBody,
              mono: true,
            ),
          ),
          _Section(
            title: 'Response Headers',
            child: _KeyValueBlock(map: entry.responseHeaders),
          ),
          _Section(
            title: 'Response',
            child: _CopyableText(
              text: entry.responseBody.isEmpty ? '—' : entry.responseBody,
              mono: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff8D8D8D),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _KeyValueBlock extends StatelessWidget {
  const _KeyValueBlock({required this.map});

  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return const Text('—', style: TextStyle(color: Color(0xff8D8D8D)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: map.entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xff1D1D1D)),
                  children: [
                    TextSpan(
                      text: '${e.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '${e.value}'),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CopyableText extends StatelessWidget {
  const _CopyableText({required this.text, this.mono = false});

  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xff1D1D1D),
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy, size: 16, color: Color(0xff8D8D8D)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied')),
              );
            }
          },
        ),
      ],
    );
  }
}

/// Color per HTTP method, shared by the badge.
Color methodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return const Color(0xff388CFF);
    case 'POST':
      return const Color(0xff34D317);
    case 'PUT':
    case 'PATCH':
      return const Color(0xffF5A623);
    case 'DELETE':
      return const Color(0xffFF5F61);
    default:
      return const Color(0xff8D8D8D);
  }
}
