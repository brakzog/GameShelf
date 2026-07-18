class CoverResult {
  final bool found;
  final Uri? downloadUrl;
  final String? localPath;

  const CoverResult({
    required this.found,
    this.downloadUrl,
    this.localPath,
  });

  const CoverResult.notFound()
      : found = false,
        downloadUrl = null,
        localPath = null;

  const CoverResult.local(this.localPath)
      : found = true,
        downloadUrl = null;

  const CoverResult.remote(this.downloadUrl)
      : found = true,
        localPath = null;
}
