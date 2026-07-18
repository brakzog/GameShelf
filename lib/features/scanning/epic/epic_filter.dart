class EpicFilter {
  const EpicFilter();

  bool shouldKeep(Map<String, dynamic> manifest) {
    final isApplication = manifest['bIsApplication'] == true;
    final isExecutable = manifest['bIsExecutable'] == true;
    final isIncompleteInstall = manifest['bIsIncompleteInstall'] == true;

    final displayName = _readString(manifest, 'DisplayName');
    final appName = _readString(manifest, 'AppName');
    final mainGameAppName = _readString(manifest, 'MainGameAppName');
    final installLocation = _readString(manifest, 'InstallLocation');
    final launchExecutable = _readString(manifest, 'LaunchExecutable');

    final isChildContent = mainGameAppName.isNotEmpty &&
        appName.isNotEmpty &&
        appName != mainGameAppName;

    return isApplication &&
        isExecutable &&
        !isIncompleteInstall &&
        displayName.isNotEmpty &&
        installLocation.isNotEmpty &&
        launchExecutable.isNotEmpty &&
        !isChildContent;
  }

  String _readString(Map<String, dynamic> manifest, String key) {
    final value = manifest[key];

    return value is String ? value.trim() : '';
  }
}
