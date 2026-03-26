// ignore_for_file: deprecated_member_use, use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(
              0xFFF3F4F6,
            ), // Very light grey/blue professional background
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "About Us",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Headline
            Text(
              "Meet the Team Behind SmartQ",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A), // Dark Blue
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "SmartQ is an innovative smart queue management application designed to simplify waiting systems and improve service efficiency through digital transformation.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),

            // Mentor Section (Redesigned with Light Background)
            _sectionTitle("Our Mentor"),
            const SizedBox(height: 16),
            _buildLightMentorCard(context),

            const SizedBox(height: 30),

            // Team Section
            _sectionTitle("The Team"),
            const SizedBox(height: 16),

            // Responsive Grid for Team Members
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTeamMemberCard(
                      context,
                      name: "Sakshi Kathawde",
                      role: "Backend Developer",
                      roleColor: Colors.blue,
                      description:
                          "Responsible for backend architecture, API integration, and ensuring system security and performance.",
                      skills: ["Node.js", "MongoDB", "Express"],
                      instagramId: "sakshi_kathawde",
                      avatarColor: Colors.blue.shade50,
                      imageAsset: "assets/sakshi.jpeg",
                    ),
                    _buildTeamMemberCard(
                      context,
                      name: "Unnati Surana",
                      role: "Frontend Developer",
                      roleColor: Colors.pinkAccent,
                      description:
                          "Focuses on creating responsive, user-friendly mobile interfaces using Flutter and ensuring cross-platform compatibility.",
                      skills: ["Flutter", "Dart", "Material"],
                      instagramId: "unnati_jain99",
                      avatarColor: Colors.pink.shade50,
                      imageAsset: "assets/unnati.jpeg",
                    ),
                    _buildTeamMemberCard(
                      context,
                      name: "Mohini Jagtap",
                      role: "UI/UX Designer",
                      roleColor: Colors.orange,
                      description:
                          "Designs the visual layout, color schemes, and user experience flows to create an intuitive and engaging app.",
                      skills: ["Figma", "Canva", "Prototyping"],
                      instagramId: "mohinijagtap6062",
                      avatarColor: Colors.orange.shade50,
                      imageAsset: "assets/mohini.jpeg",
                    ),
                    _buildTeamMemberCard(
                      context,
                      name: "Vaishali Bade",
                      role: "QA & Documentation",
                      roleColor: Colors.teal,
                      description:
                          "Manages testing, bug tracking, and preparing comprehensive project documentation and user guides.",
                      skills: ["Testing", "Docs", "Analysis"],
                      instagramId: "vaishali_bade",
                      avatarColor: Colors.teal.shade50,
                      imageAsset: "assets/vaishali.jpeg",
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Technologies Used Section
            _sectionTitle("Technologies Used"),
            const SizedBox(height: 16),
            _buildTechnologiesSection(),

            const SizedBox(height: 40),

            // Mission Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    "Our Mission",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _missionItem("Reduce waiting time substantially"),
                  _missionItem("Promote paperless queue systems"),
                  _missionItem("Support sustainable digital management"),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            Column(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
                const SizedBox(height: 8),
                Text(
                  "Made with love by SmartQ Team",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ✅ Updated Mentor Card with Light Theme
  Widget _buildLightMentorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.15),
        ), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.shade50,
              child: ClipOval(
                child: Image.asset(
                  "assets/swami-sir.jpeg", // ✅ Changed to Asset Path
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    size: 35,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Swami Sir",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Project Guide & Mentor",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Provided valuable technical direction and expert guidance to shape the system’s design and quality.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ New Technologies Section
  Widget _buildTechnologiesSection() {
    final List<Map<String, dynamic>> techs = [
      {'name': 'Flutter', 'color': Colors.blue, 'icon': Icons.flutter_dash},
      {
        'name': 'Node.js',
        'color': Colors.green,
        'icon': Icons.javascript,
      }, // Using JS icon as proxy
      {
        'name': 'MongoDB',
        'color': Colors.green.shade800,
        'icon': Icons.storage,
      },
      {'name': 'Dart', 'color': Colors.blueAccent, 'icon': Icons.code},
      {
        'name': 'Firebase',
        'color': Colors.orange,
        'icon': Icons.local_fire_department,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: techs
          .map((tech) => _techChip(tech['name'], tech['color'], tech['icon']))
          .toList(),
    );
  }

  Widget _techChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Team Member Card with Instagram Link
  Widget _buildTeamMemberCard(
    BuildContext context, {
    required String name,
    required String role,
    required Color roleColor,
    required String description,
    required List<String> skills,
    required String instagramId,
    required Color avatarColor,
    required String imageAsset, // ✅ Changed to Asset Path
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: avatarColor,
            child: ClipOval(
              child: Image.asset(
                imageAsset,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: 40,
                  color: roleColor.withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),

          // Instagram Link
          InkWell(
            onTap: () => _launchInstagram(context, instagramId),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instagram Icon (Using generic camera icon as closest match if social icons not available)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFC13584),
                        Color(0xFFE1306C),
                        Color(0xFFFD1D1D),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "@$instagramId",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600, // Slightly bolder for link
                      color: Colors.pink[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Launch Instagram Function
  Future<void> _launchInstagram(BuildContext context, String username) async {
    final cleanUsername = username.replaceAll('@', '');
    final Uri webUrl = Uri.parse("https://www.instagram.com/$cleanUsername");

    try {
      if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not open Instagram for @$cleanUsername"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open Instagram for @$cleanUsername"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
