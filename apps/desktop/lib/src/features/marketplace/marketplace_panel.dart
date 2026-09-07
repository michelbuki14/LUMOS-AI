import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 8a — Marketplace (plugin/preset store) — local-first, offline browse, cloud optional

class MarketplaceItem {
  final String id; final String title; final String author; final double price; final double rating; final String kind; // preset / luts / plugin
  const MarketplaceItem(this.id,this.title,this.author,this.price,this.rating,this.kind);
}
final _demoItems = [
  MarketplaceItem('p1','Golden Hour Wedding','Lumos Lab',0,4.9,'preset'),
  MarketplaceItem('p2','Feather Detail v2','Wildlight',12,4.7,'preset'),
  MarketplaceItem('p3','Sky Replace Ultra','SkyLab',19,4.8,'plugin'),
  MarketplaceItem('p4','Pure White Product','Studio Pro',0,4.6,'preset'),
  MarketplaceItem('p5','Film Grain 35mm','Grain Co',9,4.5,'luts'),
];

final marketFilterProvider = StateProvider<String>((_)=> 'all'); // all / preset / plugin / luts
final marketInstalledProvider = StateProvider<Set<String>>((_)=> {'p1'});

class MarketplacePanel extends ConsumerWidget{
  const MarketplacePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final filter=ref.watch(marketFilterProvider);
    final installed=ref.watch(marketInstalledProvider);
    final items = filter=='all'? _demoItems : _demoItems.where((e)=> e.kind==filter).toList();
    return Column(children:[
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Marketplace', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height:4),
        const Text('Presets, LUTs, plugins. Install locally, run offline.', style: TextStyle(fontSize:11, color: Colors.white54)),
        const SizedBox(height:12),
        Wrap(spacing:6, children: ['all','preset','plugin','luts'].map((k)=> ChoiceChip(label: Text(k, style: const TextStyle(fontSize:11)), selected: filter==k, onSelected: (_)=> ref.read(marketFilterProvider.notifier).state=k)).toList()),
      ])),
      Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: items.length, separatorBuilder: (_,__)=> const SizedBox(height:8),
        itemBuilder: (_,i){
          final it=items[i];
          final isInstalled=installed.contains(it.id);
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
            child: Row(children:[
              Container(width:40, height:40, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha:0.2), borderRadius: BorderRadius.circular(8)), child: Icon(switch(it.kind){'preset'=>Icons.style,'plugin'=>Icons.extension,'luts'=>Icons.palette_outlined,_=>Icons.inventory_2}, size:18, color: Colors.white70)),
              const SizedBox(width:10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Text(it.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                Text('${it.author} • ${it.kind} • ★ ${it.rating}', style: const TextStyle(fontSize:11, color: Colors.white54)),
              ])),
              Column(children:[
                Text(it.price==0? 'FREE' : '\$${it.price.toInt()}', style: TextStyle(fontSize:12, fontWeight: FontWeight.bold, color: it.price==0? Colors.greenAccent : Colors.white)),
                const SizedBox(height:4),
                SizedBox(height:28, child: isInstalled
                  ? OutlinedButton(onPressed: null, child: const Text('Installed', style: TextStyle(fontSize:11)))
                  : FilledButton(onPressed: (){ ref.read(marketInstalledProvider.notifier).state={...installed, it.id}; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Installed ${it.title}'))); }, child: const Text('Install', style: TextStyle(fontSize:11)))),
              ]),
            ]),
          );
        })),
      const Padding(padding: EdgeInsets.all(12), child: Text('Runs locally after install. No GPU-second metering.', style: TextStyle(fontSize:11, color: Colors.white54))),
    ]);
  }
}
