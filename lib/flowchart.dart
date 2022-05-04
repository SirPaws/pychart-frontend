import 'package:flutter/material.dart';
import 'package:docking/docking.dart';

import 'main.dart';

class FlowChartView extends DockingItem {
    FlowChartView(MyHomePage widget) : super(
        name: 'flowchart', 
        closable: false, 
        maximizable: true,
        widget: const Center(child: Text('much wow!'))
    );
}
