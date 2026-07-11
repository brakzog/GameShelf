class VdfParser {
  final String _input;
  int _index = 0;

  VdfParser(this._input);

  static Map<String, dynamic> parse(String input) {
    return VdfParser(input)._parseRoot();
  }

  Map<String, dynamic> _parseRoot() {
    final result = <String, dynamic>{};
    while (true) {
      _skipWhitespaceAndComments();
      if (_isAtEnd) break;
      final key = _readToken();
      if (key == null) break;
      _skipWhitespaceAndComments();
      if (_peek() == '{') {
        _index++;
        result[key] = _parseObject();
      } else {
        result[key] = _readToken() ?? '';
      }
    }
    return result;
  }

  Map<String, dynamic> _parseObject() {
    final result = <String, dynamic>{};
    while (true) {
      _skipWhitespaceAndComments();
      if (_isAtEnd) break;
      if (_peek() == '}') {
        _index++;
        break;
      }

      final key = _readToken();
      if (key == null) break;
      _skipWhitespaceAndComments();

      if (_peek() == '{') {
        _index++;
        result[key] = _parseObject();
      } else {
        result[key] = _readToken() ?? '';
      }
    }
    return result;
  }

  String? _readToken() {
    _skipWhitespaceAndComments();
    if (_isAtEnd) return null;

    if (_peek() == '"') return _readQuotedString();

    final start = _index;
    while (!_isAtEnd) {
      final char = _peek();
      if (char.trim().isEmpty || char == '{' || char == '}') break;
      _index++;
    }
    if (start == _index) return null;
    return _input.substring(start, _index);
  }

  String _readQuotedString() {
    _index++;
    final buffer = StringBuffer();

    while (!_isAtEnd) {
      final char = _input[_index++];
      if (char == '"') break;
      if (char == r'\\' && !_isAtEnd) {
        final next = _input[_index++];
        if (next == 'n') {
          buffer.write('\n');
        } else if (next == 't') {
          buffer.write('\t');
        } else {
          buffer.write(next);
        }
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  void _skipWhitespaceAndComments() {
    while (!_isAtEnd) {
      final char = _peek();
      if (char.trim().isEmpty) {
        _index++;
        continue;
      }
      if (char == '/' && _index + 1 < _input.length && _input[_index + 1] == '/') {
        _index += 2;
        while (!_isAtEnd && _peek() != '\n') {
          _index++;
        }
        continue;
      }
      break;
    }
  }

  bool get _isAtEnd => _index >= _input.length;
  String _peek() => _input[_index];
}
