import 'package:flutter/material.dart';

class ReportListPage extends StatelessWidget {
  const ReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报告页')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '报告页面骨架已就绪，后续将在这里接入报告列表与详情入口。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
