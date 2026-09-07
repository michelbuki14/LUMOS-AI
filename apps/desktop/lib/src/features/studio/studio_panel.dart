import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 8c — Studio Management (clients, invoices, bookings) — minimal viable
class Client{ final String name; final String email; final int jobs; const Client(this.name,this.email,this.jobs); }
const _clients=[Client('Ava Studio','ava@studio.com',12), Client('North Real Estate','north@re.co',34), Client('Belle Weddings','hello@belle.wed',8)];

final studioTabProvider = StateProvider<int>((_)=>0);

class StudioPanel extends ConsumerWidget{
  const StudioPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final tab=ref.watch(studioTabProvider);
    return Column(children:[
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Studio', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height:4),
        const Text('Clients, bookings, invoices — local DB; export CSV.', style: TextStyle(fontSize:11, color: Colors.white54)),
        const SizedBox(height:12),
        SegmentedButton<int>(segments: const [ButtonSegment(value:0, label: Text('Clients', style: TextStyle(fontSize:11)), icon: Icon(Icons.people, size:14)), ButtonSegment(value:1, label: Text('Bookings', style: TextStyle(fontSize:11)), icon: Icon(Icons.calendar_today, size:14)), ButtonSegment(value:2, label: Text('Invoices', style: TextStyle(fontSize:11)), icon: Icon(Icons.receipt, size:14))], selected: {tab}, onSelectionChanged: (v)=> ref.read(studioTabProvider.notifier).state=v.first),
      ])),
      Expanded(child: switch(tab){
        0 => ListView.separated(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: _clients.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
          final c=_clients[i];
          return ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF6366F1), child: Text(c.name[0])), title: Text(c.name, style: const TextStyle(fontSize:13, fontWeight: FontWeight.w600)), subtitle: Text(c.email, style: const TextStyle(fontSize:11, color: Colors.white54)), trailing: Text('${c.jobs} jobs', style: const TextStyle(fontSize:11, color: Colors.white70)), tileColor: Colors.white.withValues(alpha:0.06), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
        }),
        1 => ListView(padding: const EdgeInsets.all(16), children: [
          _row('Today 10:00','Wedding — Belle','Confirmed', Colors.greenAccent),
          _row('Tomorrow 09:00','RE Shoot — North','Pending', Colors.orangeAccent),
          _row('Fri 14:00','Portrait — Ava','Draft', Colors.white54),
          const SizedBox(height:12),
          FilledButton.icon(onPressed: (){}, icon: const Icon(Icons.add, size:16), label: const Text('New booking')),
        ]),
        _ => ListView(padding: const EdgeInsets.all(16), children:[
          _row('INV-001','Belle Weddings — \$2,400','Paid', Colors.greenAccent),
          _row('INV-002','North RE — \$850','Sent', Colors.orangeAccent),
          _row('INV-003','Ava Studio — \$1,200','Overdue', Colors.redAccent),
          const SizedBox(height:12),
          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.download, size:16), label: const Text('Export CSV')),
        ]),
      }),
    ]);
  }
  Widget _row(String a, String b, String badge, Color c)=> Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)), child: Row(children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(a, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w600)), Text(b, style: const TextStyle(fontSize:11, color: Colors.white70))])), Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: c.withValues(alpha:0.18), borderRadius: BorderRadius.circular(99), border: Border.all(color: c.withValues(alpha:0.4))), child: Text(badge, style: TextStyle(fontSize:11, color:c))) ]));
}
