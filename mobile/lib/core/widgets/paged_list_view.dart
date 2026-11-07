import 'package:flutter/material.dart';

import '../pagination/paged_list_notifier.dart';
import 'feedback.dart';

/// Liste paginée à scroll infini, avec pull-to-refresh, état vide et erreur.
///
/// Les écrans fournissent seulement un [fetcher] (qui capture leurs filtres)
/// et un [itemBuilder]. Changer [filtresKey] recharge depuis la première page ;
/// [PagedListViewState.refresh] (via une GlobalKey) recharge après une action.
class PagedListView<T> extends StatefulWidget {
  final PageFetcher<T> fetcher;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Object? filtresKey;
  final EdgeInsetsGeometry padding;

  /// Bouton proposé sur l'état vide (« Ajouter un immeuble »).
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  const PagedListView({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.emptyMessage = 'Aucun élément.',
    this.emptyIcon = Icons.inbox_outlined,
    this.filtresKey,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 32),
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  @override
  State<PagedListView<T>> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final _notifier = PagedListNotifier<T>();
  final _scroll = ScrollController();
  PagedListState<T> _state = PagedListState<T>();
  void Function()? _removeListener;

  @override
  void initState() {
    super.initState();
    _removeListener = _notifier.addListener((s) {
      if (mounted) setState(() => _state = s);
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _notifier.loadMore();
      }
    });
    _notifier.load(widget.fetcher);
  }

  @override
  void didUpdateWidget(covariant PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filtresKey != widget.filtresKey) {
      _notifier.load(widget.fetcher);
    }
  }

  Future<void> refresh() => _notifier.load(widget.fetcher);

  @override
  void dispose() {
    _removeListener?.call();
    _notifier.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s.initialLoading && s.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.error != null && s.items.isEmpty) {
      return ErrorView(message: s.error!, onRetry: refresh);
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: s.items.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              EmptyState(
                icon: widget.emptyIcon,
                message: widget.emptyMessage,
                actionLabel: widget.emptyActionLabel,
                onAction: widget.onEmptyAction,
              ),
            ])
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding,
              itemCount: s.items.length + (s.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => i >= s.items.length
                  ? const PagedListLoadMoreTile()
                  : widget.itemBuilder(context, s.items[i]),
            ),
    );
  }
}
