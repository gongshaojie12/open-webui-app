import 'package:conduit/shared/widgets/markdown/markdown_preprocessor.dart';
import 'package:conduit/shared/widgets/markdown/renderer/details_block_syntax.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

void main() {
  bool hasDetails(List<md.Node> nodes) => nodes.any(
    (n) =>
        n is md.Element &&
        (n.tag == 'details' ||
            (n.tag == 'div' &&
                (n.children ?? const <md.Node>[]).any(
                  (c) => c is md.Element && c.tag == 'details',
                ))),
  );

  List<md.Node> compileWithRepair(String raw) {
    final repaired = ConduitMarkdownPreprocessor.repairEscapedSemanticDetails(
      raw,
    );
    final normalized = ConduitMarkdownPreprocessor.normalize(repaired);
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      blockSyntaxes: const [DetailsBlockSyntax()],
      encodeHtml: false,
    );
    return document.parse(normalized);
  }

  test('escaped reasoning block (from screenshot) now collapses', () {
    // Byte-shape from docs/3.jpg debug box: fully HTML-escaped semantic details.
    const escaped =
        '&lt;details type=&quot;reasoning&quot; done=&quot;true&quot; duration=&quot;20&quot;&gt;\n'
        '&lt;summary&gt;Thought for 20 seconds&lt;/summary&gt;\n'
        '&gt; Developing Coca-Cola Proposal Strategy\n'
        '&gt; \n'
        "&gt; I'm currently zeroing in on the core strategic pillars.\n"
        '&lt;/details&gt;\n'
        'Here is the visible answer.';

    final repaired = ConduitMarkdownPreprocessor.repairEscapedSemanticDetails(
      escaped,
    );
    print('REPAIRED>>>\n$repaired\n<<<');

    final nodes = compileWithRepair(escaped);
    expect(hasDetails(nodes), isTrue,
        reason: 'escaped reasoning must collapse after repair');

    // The details element must carry the reasoning type + summary.
    final details = _findDetails(nodes)!;
    expect(details.attributes['type'], 'reasoning');
    expect(details.attributes['done'], 'true');
    expect(details.attributes['duration'], '20');
  });

  test('bare escaped <details> from image-gen pipe (no type) collapses', () {
    // Byte-shape from docs/5.jpg debug box: BARE escaped <details> (no type
    // attribute), Chinese summary, blockquote body, then image.
    const escaped =
        '&lt;details&gt;\n'
        '&lt;summary&gt;思考用时 (24s)&lt;/summary&gt;\n'
        '\n'
        '&gt; **Generating Adorable Canine**\n'
        '&gt; \n'
        "&gt; I'm focusing on creating a very cute puppy.\n"
        '&lt;/details&gt;\n'
        '\n'
        '![Generated Image](https://example.com/img.png)';

    final repaired = ConduitMarkdownPreprocessor.repairEscapedSemanticDetails(
      escaped,
    );
    print('BARE REPAIRED>>>\n$repaired\n<<<');
    expect(hasDetails(compileWithRepair(escaped)), isTrue,
        reason: 'bare escaped image-gen details must collapse after repair');

    final details = _findDetails(compileWithRepair(escaped))!;
    // No type attribute on the bare block.
    expect(details.attributes['type'], isNull);
    // The image after the block must still be present as a separate node.
    expect(escaped.contains('![Generated Image]'), isTrue);
  });

  test('double-escaped body (&amp;gt;) still collapses', () {
    const escaped =
        '&lt;details type=&quot;reasoning&quot; done=&quot;true&quot; duration=&quot;20&quot;&gt;\n'
        '&lt;summary&gt;Thought for 20 seconds&lt;/summary&gt;\n'
        '&amp;gt; Developing Coca-Cola Proposal Strategy\n'
        '&lt;/details&gt;';
    final nodes = compileWithRepair(escaped);
    expect(hasDetails(nodes), isTrue);
  });

  test('plain (correct) reasoning block is untouched and still collapses', () {
    const plain =
        '<details type="reasoning" done="true" duration="20">\n'
        '<summary>Thought for 20 seconds</summary>\n'
        '&gt; body line\n'
        '</details>\n'
        'Visible answer';
    // repair must be a no-op on already-correct content.
    expect(
      ConduitMarkdownPreprocessor.repairEscapedSemanticDetails(plain),
      plain,
    );
    expect(hasDetails(compileWithRepair(plain)), isTrue);
  });

  test('ordinary escaped &lt;details&gt; WITHOUT semantic type is NOT touched',
      () {
    // A user pasting escaped HTML text that is not a semantic block must stay
    // as literal text (no accidental unescape).
    const text = 'Example: &lt;details&gt;hello&lt;/details&gt; in a sentence.';
    expect(
      ConduitMarkdownPreprocessor.repairEscapedSemanticDetails(text),
      text,
    );
  });
}

md.Element? _findDetails(List<md.Node> nodes) {
  for (final n in nodes) {
    if (n is md.Element) {
      if (n.tag == 'details') return n;
      final child = _findDetails(n.children ?? const <md.Node>[]);
      if (child != null) return child;
    }
  }
  return null;
}
