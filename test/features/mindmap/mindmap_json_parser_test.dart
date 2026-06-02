import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_json_parser.dart';

void main() {
  const validJson = '''
{
  "title": "Sơ đồ Toán",
  "rootId": "n1",
  "clusters": [
    { "id": "c1", "label": "Khái niệm", "color": "#5C6BC0" }
  ],
  "nodes": [
    { "id": "n1", "label": "Gốc", "parentId": null, "clusterId": "c1" },
    { "id": "n2", "label": "Nhánh A", "parentId": "n1", "clusterId": "c1" },
    { "id": "n3", "label": "Nhánh B", "parentId": "n1", "clusterId": "c1" },
    { "id": "n4", "label": "Chi tiết", "parentId": "n2", "clusterId": "c1" }
  ]
}
''';

  test('parse valid mindmap tree', () {
    final result = MindmapJsonParser.parse(
      sessionId: 's1',
      rawJson: validJson,
    );
    expect(result.isSuccess, isTrue);
    final map = result.valueOrNull!;
    expect(map.rootId, 'n1');
    expect(map.nodes.length, 4);
    expect(map.root?.childIds.length, 2);
  });

  test('rejects disconnected node', () {
    const json = '''
{
  "title": "Bad",
  "rootId": "n1",
  "nodes": [
    { "id": "n1", "label": "Gốc" },
    { "id": "n2", "label": "A", "parentId": "n1" },
    { "id": "n3", "label": "B", "parentId": "n1" },
    { "id": "n4", "label": "C", "parentId": "n1" },
    { "id": "orphan", "label": "X", "parentId": "n9" }
  ]
}
''';
    final result = MindmapJsonParser.parse(sessionId: 's1', rawJson: json);
    expect(result.isSuccess, isFalse);
  });
}
