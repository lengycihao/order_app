import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lib_base/logging/logging.dart';

/// 健壮的图片加载组件，支持重试机制
class RobustImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableRetry;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  const RobustImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.enableRetry = true,
    this.onImageLoaded,
    this.onImageError,
  }) : super(key: key);

  @override
  State<RobustImageWidget> createState() => _RobustImageWidgetState();
}

class _RobustImageWidgetState extends State<RobustImageWidget> {
  int _retryCount = 0;
  bool _isRetrying = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(RobustImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryCount = 0;
      _isRetrying = false;
      _currentImageUrl = widget.imageUrl;
    }
  }

  /// 重试加载图片
  Future<void> _retryLoadImage() async {
    if (!widget.enableRetry || _retryCount >= widget.maxRetries || _isRetrying) {
      return;
    }

    setState(() {
      _isRetrying = true;
    });

    await Future.delayed(widget.retryDelay);

    if (mounted) {
      setState(() {
        _retryCount++;
        _isRetrying = false;
        // 添加时间戳参数强制重新加载
        _currentImageUrl = '${widget.imageUrl}${widget.imageUrl.contains('?') ? '&' : '?'}retry=$_retryCount&t=${DateTime.now().millisecondsSinceEpoch}';
      });
      
      logDebug('🔄 图片重试加载: ${widget.imageUrl}, 重试次数: $_retryCount', tag: 'RobustImageWidget');
    }
  }

  /// 构建占位符
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Image.asset(
          'assets/order_menu_placeholder.webp',
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return GestureDetector(
      onTap: _retryLoadImage,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: Image.asset(
            'assets/order_menu_placeholder.webp',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 构建重试中的组件
  Widget _buildRetryingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: (widget.width != null && widget.width! < 20) ? widget.width! * 0.6 : 20,
          height: (widget.height != null && widget.height! < 20) ? widget.height! * 0.6 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果图片URL为空，显示占位符
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // 如果正在重试，显示重试中组件
    if (_isRetrying) {
      return _buildRetryingWidget();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: _currentImageUrl ?? widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          // 记录错误日志
          // logError('图片加载失败: $url, 错误: $error', tag: 'RobustImageWidget');
          
          // 触发错误回调
          widget.onImageError?.call();
          
          // 如果启用重试且未达到最大重试次数，自动重试
          if (widget.enableRetry && _retryCount < widget.maxRetries) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _retryLoadImage();
            });
          }
          
          return _buildErrorWidget();
        },
        imageBuilder: (context, imageProvider) {
          // 图片加载成功，触发成功回调
          widget.onImageLoaded?.call();
          
          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
        // 添加缓存配置
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
        maxWidthDiskCache: (widget.width != null ? widget.width! * 2 : 400).toInt(),
        maxHeightDiskCache: (widget.height != null ? widget.height! * 2 : 400).toInt(),
      ),
    );
  }
}

/// 菜品图片专用组件
class DishImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  const DishImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.onImageLoaded,
    this.onImageError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RobustImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
      enableRetry: true,
      onImageLoaded: onImageLoaded,
      onImageError: onImageError,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Image.asset(
            'assets/order_menu_placeholder.webp',
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Image.asset(
            'assets/order_menu_placeholder.webp',
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

