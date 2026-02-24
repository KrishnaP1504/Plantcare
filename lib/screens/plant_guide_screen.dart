import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';
import '../widgets/custom_bottom_nav.dart';

class PlantGuideScreen extends StatefulWidget {
  const PlantGuideScreen({super.key});

  @override
  State<PlantGuideScreen> createState() => _PlantGuideScreenState();
}

class _PlantGuideScreenState extends State<PlantGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _userPlantNames = []; 

  final List<Map<String, dynamic>> _allTips = [
    {
      "id": "1",
      "title": "How to water succulents",
      "subtitle": "5 min read",
      "icon": LucideIcons.droplets,
      "color": const Color(0xFFE8F5E9),
      "iconColor": const Color(0xFF2E7D32),
      "tags": ["succulent", "cactus", "aloe", "jade", "watering"],
      "content": "Succulents love the 'soak and dry' method. Soak the soil completely, then let it dry out completely before watering again. Never spray water on the leaves directly."
    },
    {
      "id": "2",
      "title": "Best soil for indoor plants",
      "subtitle": "3 min read",
      "icon": LucideIcons.sprout,
      "color": const Color(0xFFFFF3E0),
      "iconColor": const Color(0xFFEF6C00),
      "tags": ["soil", "indoor", "potting", "general"],
      "content": "Indoor plants need well-draining soil. A mix of peat moss, perlite, and pine bark is usually best to prevent root rot."
    },
    {
      "id": "3",
      "title": "Dealing with pests",
      "subtitle": "7 min read",
      "icon": LucideIcons.bug,
      "color": const Color(0xFFFFEBEE),
      "iconColor": const Color(0xFFC62828),
      "tags": ["pests", "bugs", "spider mites", "aphids", "troubleshooting"],
      "content": "Common pests like aphids can be treated with Neem Oil. Wipe leaves regularly to prevent infestations."
    },
    {
      "id": "4",
      "title": "Fixing Yellow Leaves",
      "subtitle": "4 min read",
      "icon": LucideIcons.alertTriangle,
      "color": const Color(0xFFFFF8E1),
      "iconColor": const Color(0xFFF9A825),
      "tags": ["yellow", "leaves", "sick", "health", "troubleshooting"],
      "content": "Yellow leaves often mean overwatering. Check if the soil is soggy. If it's dry, it might be nutrient deficiency (Nitrogen)."
    },
    {
      "id": "5",
      "title": "Sunlight requirements",
      "subtitle": "4 min read",
      "icon": LucideIcons.sun,
      "color": const Color(0xFFFFFDE7),
      "iconColor": const Color(0xFFFBC02D),
      "tags": ["sun", "light", "location", "general"],
      "content": "South-facing windows offer the brightest light. East-facing are good for gentle morning sun."
    },
    {
      "id": "6",
      "title": "Caring for Roses",
      "subtitle": "6 min read",
      "icon": LucideIcons.flower2,
      "color": const Color(0xFFFCE4EC),
      "iconColor": const Color(0xFFD81B60),
      "tags": ["rose", "flower", "outdoor"],
      "content": "Roses are hungry plants! Fertilize them often and prune dead flowers to encourage new blooms."
    },
  ];

  final List<String> _searchSuggestions = [
    "Yellow leaves",
    "Brown tips",
    "Root rot",
    "Pests",
    "Succulents",
    "Low light",
    "Fertilizer",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSortedTips() {
    var filtered = _allTips;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = _allTips.where((tip) {
        final title = tip['title'].toString().toLowerCase();
        final tags = (tip['tags'] as List<String>).join(" ").toLowerCase();
        return title.contains(query) || tags.contains(query);
      }).toList();
    }

    final List<Map<String, dynamic>> forYou = [];
    final List<Map<String, dynamic>> others = [];

    for (var tip in filtered) {
      bool isRelevant = false;
      for (var plantName in _userPlantNames) {
        if ((tip['tags'] as List<String>).contains(plantName.toLowerCase())) {
          isRelevant = true;
          break;
        }
      }
      
      // FIX: Added curly braces for flow control compliance
      if (isRelevant) {
        forYou.add(tip);
      } else {
        others.add(tip);
      }
    }

    return [...forYou, ...others];
  }

  void _openTip(BuildContext context, Map<String, dynamic> tip) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TipDetailScreen(tip: tip)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text("Plant Guide", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const Text("Expert tips personalized for you", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            decoration: const InputDecoration(
                              hintText: "Search 'Yellow leaves', 'Pests'...",
                              prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16)
                            ),
                          ),
                          if (_searchQuery.isNotEmpty && _getSortedTips().isEmpty)
                             ..._searchSuggestions.where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase())).map((s) => 
                               InkWell(
                                 onTap: () {
                                   _searchController.text = s;
                                   setState(() => _searchQuery = s);
                                 },
                                 child: Container(
                                   width: double.infinity,
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                   decoration: const BoxDecoration(
                                     border: Border(top: BorderSide(color: Colors.black12))
                                   ),
                                   child: Row(
                                     children: [
                                       const Icon(LucideIcons.arrowUpRight, size: 16, color: Colors.grey),
                                       const SizedBox(width: 8),
                                       Text(s, style: const TextStyle(color: AppTheme.primary)),
                                     ],
                                   )
                                 ),
                               )
                             )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('my_plants').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          _userPlantNames = snapshot.data!.docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return (data['name'] ?? '').toString().split(' ')[0];
                          }).toList();
                        }
                        
                        final displayTips = _getSortedTips();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_userPlantNames.isNotEmpty && _searchQuery.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(bottom: 16),
                                 child: Row(
                                   children: [
                                     const Icon(LucideIcons.sparkles, size: 18, color: AppTheme.primary),
                                     const SizedBox(width: 8),
                                     Text("For Your Garden", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                   ],
                                 ),
                               ),

                            if (displayTips.isEmpty)
                               const Padding(
                                 padding: EdgeInsets.all(24.0),
                                 child: Center(child: Text("No tips found matching that search.", style: TextStyle(color: Colors.grey))),
                               ),

                            ...displayTips.map((tip) {
                              bool isRecommended = false;
                              for(var name in _userPlantNames) {
                                if ((tip['tags'] as List).contains(name.toLowerCase())) isRecommended = true;
                              }

                              return GestureDetector(
                                onTap: () => _openTip(context, tip),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                                    border: isRecommended && _searchQuery.isEmpty ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2) : null
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(color: tip['color'], borderRadius: BorderRadius.circular(12)),
                                        child: Center(child: Icon(tip['icon'], color: tip['iconColor'], size: 28)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isRecommended && _searchQuery.isEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4)),
                                                child: const Text("RECOMMENDED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: Text("TIP", style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            Text(tip['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                            const SizedBox(height: 4),
                                            Text(tip['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20)
                                    ],
                                  ),
                                ),
                              );
                            }),
                            
                            const SizedBox(height: 100),
                          ],
                        );
                      }
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const CustomBottomNav(active: 3),
        ],
      ),
    );
  }
}

class TipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tip;
  const TipDetailScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: tip['color'], borderRadius: BorderRadius.circular(20)),
              child: Center(child: Icon(tip['icon'], color: tip['iconColor'], size: 40)),
            ),
            const SizedBox(height: 24),
            Text(tip['title'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(tip['subtitle'], style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            Text(
              tip['content'],
              style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(child: Text("Always identify your specific plant species before applying major treatments.", style: TextStyle(color: Colors.blue, fontSize: 14))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}