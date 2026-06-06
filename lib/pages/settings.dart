// pages/settings.dart
import 'package:flutter/material.dart';
import '../providers/settings.dart';

class SettingsPage extends StatefulWidget {
  final SettingsProvider settingsProvider;

  const SettingsPage({super.key, required this.settingsProvider});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsProvider _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsProvider;

    // ✅ 添加监听器
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(color: Color(0xFF386b42))),
        backgroundColor: const Color(0xFFb0e8b8),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 背景图片设置
          _buildSectionTitle('背景图片'),
          _buildBackgroundImageCard(),  // ✅ 直接调用，不用 Consumer
          const SizedBox(height: 20),

          // 颜色设置
          _buildSectionTitle('颜色配置'),
          _buildColorSettingCard(),
          const SizedBox(height: 20),

          // 模糊度设置
          _buildSectionTitle('模糊效果'),
          _buildBlurSettingCard(),
          const SizedBox(height: 20),

          // 重置按钮
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF386b42),
        ),
      ),
    );
  }

  Widget _buildBackgroundImageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF386b42)),
              title: const Text('背景图片路径'),
              subtitle: Text(
                _settings.backgroundImagePath ?? '未设置（使用默认图片）',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF386b42)),
                    onPressed: () => _showImagePathDialog(),
                  ),
                  if (_settings.backgroundImagePath != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        _settings.updateBackgroundImage(null);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '提示：输入本地路径如 assets/images/bg.jpg 或网络图片URL',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSettingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildColorPickerTile(
              '搜索栏颜色',
              _settings.colors.searchBarColor,
              (color) => _settings.updateSearchBarColor(color),
            ),
            const Divider(),
            _buildColorPickerTile(
              '文字和按钮颜色',
              _settings.colors.textButtonColor,
              (color) => _settings.updateTextButtonColor(color),
            ),
            const Divider(),
            _buildColorPickerTile(
              '按钮背景色',
              _settings.colors.buttonBgColor,
              (color) => _settings.updateButtonBgColor(color),
            ),
            const Divider(),
            _buildColorPickerTile(
              '歌曲列表背景色',
              _settings.colors.listBgColor,
              (color) => _settings.updateListBgColor(color),
            ),
            const Divider(),
            _buildColorPickerTile(
              '播放控制栏背景色',
              _settings.colors.controlBarColor,
              (color) => _settings.updateControlBarColor(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickerTile(String title, Color currentColor, Function(Color) onColorSelected) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Color(0xFF386b42)),
            onPressed: () async {
              final Color? pickedColor = await showDialog(
                context: context,
                builder: (context) => _buildColorPickerDialog(currentColor),
              );
              if (pickedColor != null) {
                onColorSelected(pickedColor);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerDialog(Color initialColor) {
    Color selectedColor = initialColor;
    // ✅ 将 controller 定义在这里
    final TextEditingController hexController = TextEditingController(
      text: _colorToHex(initialColor),
    );

    return AlertDialog(
      title: const Text('选择颜色'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 颜色预览
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),

                // HEX 输入框
                TextField(
                  controller: hexController,
                  decoration: const InputDecoration(
                    labelText: 'HEX 颜色值',
                    hintText: '#FF386B42',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                  onChanged: (value) {
                    final Color? parsedColor = _hexToColor(value);
                    if (parsedColor != null) {
                      setState(() {
                        selectedColor = parsedColor;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 打开高级选择器按钮
                ElevatedButton(
                  onPressed: () async {
                    final Color? picked = await _showColorPicker(context, selectedColor);
                    if (picked != null) {
                      setState(() {
                        selectedColor = picked;
                        hexController.text = _colorToHex(picked);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFb0e8b8),
                  ),
                  child: const Text('打开颜色选择器', style: TextStyle(color: Color(0xFF386b42))),
                ),
                const SizedBox(height: 8),
                const Text(
                  '提示：支持 #RRGGBB 或 #AARRGGBB 格式',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final Color? finalColor = _hexToColor(hexController.text);
            Navigator.pop(context, finalColor ?? selectedColor);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Future<Color?> _showColorPicker(BuildContext context, Color initialColor) async {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = initialColor;
        // ✅ 将 controller 定义在这里
        final TextEditingController hexController = TextEditingController(
          text: _colorToHex(initialColor),
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择颜色'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 颜色预览
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: tempColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // HEX 输入框
                    TextField(
                      controller: hexController,
                      decoration: const InputDecoration(
                        labelText: 'HEX 颜色值',
                        hintText: '#FF386B42',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                      onChanged: (value) {
                        final Color? parsedColor = _hexToColor(value);
                        if (parsedColor != null) {
                          setState(() {
                            tempColor = parsedColor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 预设颜色
                    const Text('预设颜色', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildColorOption(Colors.red, () => setState(() {
                          tempColor = Colors.red;
                          hexController.text = _colorToHex(Colors.red);
                        })),
                        _buildColorOption(Colors.pink, () => setState(() {
                          tempColor = Colors.pink;
                          hexController.text = _colorToHex(Colors.pink);
                        })),
                        _buildColorOption(Colors.purple, () => setState(() {
                          tempColor = Colors.purple;
                          hexController.text = _colorToHex(Colors.purple);
                        })),
                        _buildColorOption(Colors.deepPurple, () => setState(() {
                          tempColor = Colors.deepPurple;
                          hexController.text = _colorToHex(Colors.deepPurple);
                        })),
                        _buildColorOption(Colors.indigo, () => setState(() {
                          tempColor = Colors.indigo;
                          hexController.text = _colorToHex(Colors.indigo);
                        })),
                        _buildColorOption(Colors.blue, () => setState(() {
                          tempColor = Colors.blue;
                          hexController.text = _colorToHex(Colors.blue);
                        })),
                        _buildColorOption(Colors.lightBlue, () => setState(() {
                          tempColor = Colors.lightBlue;
                          hexController.text = _colorToHex(Colors.lightBlue);
                        })),
                        _buildColorOption(Colors.cyan, () => setState(() {
                          tempColor = Colors.cyan;
                          hexController.text = _colorToHex(Colors.cyan);
                        })),
                        _buildColorOption(Colors.teal, () => setState(() {
                          tempColor = Colors.teal;
                          hexController.text = _colorToHex(Colors.teal);
                        })),
                        _buildColorOption(Colors.green, () => setState(() {
                          tempColor = Colors.green;
                          hexController.text = _colorToHex(Colors.green);
                        })),
                        _buildColorOption(Colors.lightGreen, () => setState(() {
                          tempColor = Colors.lightGreen;
                          hexController.text = _colorToHex(Colors.lightGreen);
                        })),
                        _buildColorOption(Colors.lime, () => setState(() {
                          tempColor = Colors.lime;
                          hexController.text = _colorToHex(Colors.lime);
                        })),
                        _buildColorOption(Colors.yellow, () => setState(() {
                          tempColor = Colors.yellow;
                          hexController.text = _colorToHex(Colors.yellow);
                        })),
                        _buildColorOption(Colors.orange, () => setState(() {
                          tempColor = Colors.orange;
                          hexController.text = _colorToHex(Colors.orange);
                        })),
                        _buildColorOption(Colors.deepOrange, () => setState(() {
                          tempColor = Colors.deepOrange;
                          hexController.text = _colorToHex(Colors.deepOrange);
                        })),
                        _buildColorOption(Colors.brown, () => setState(() {
                          tempColor = Colors.brown;
                          hexController.text = _colorToHex(Colors.brown);
                        })),
                        _buildColorOption(Colors.grey, () => setState(() {
                          tempColor = Colors.grey;
                          hexController.text = _colorToHex(Colors.grey);
                        })),
                        _buildColorOption(Colors.blueGrey, () => setState(() {
                          tempColor = Colors.blueGrey;
                          hexController.text = _colorToHex(Colors.blueGrey);
                        })),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final Color? finalColor = _hexToColor(hexController.text);
                    Navigator.pop(context, finalColor ?? tempColor);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildBlurSettingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSliderTile(
              '搜索栏模糊度',
              _settings.searchBarBlur,
              0.0,
              10.0,
              (value) {
                _settings.updateSearchBarBlur(value);
              },
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              '面板模糊度',
              _settings.panelBlur,
              0.0,
              30.0,
              (value) {
                _settings.updatePanelBlur(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                activeColor: const Color(0xFF46c9cc),
                inactiveColor: const Color(0xFFb0e8b8),
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('重置所有设置'),
              content: const Text('确定要恢复所有设置为默认值吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    _settings.resetToDefault();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已恢复默认设置')),
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF46c9cc),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('重置所有设置', style: TextStyle(color: Color(0xFF386b42), fontSize: 16)),
      ),
    );
  }

  void _showImagePathDialog() {
    final controller = TextEditingController(text: _settings.backgroundImagePath);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置背景图片'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入图片路径或URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _settings.updateBackgroundImage(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 在 _SettingsPageState 类的末尾，最后一个方法后面添加

  // Color 转 HEX 字符串
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // HEX 字符串转 Color
  Color? _hexToColor(String hex) {
    hex = hex.trim().toUpperCase();

    // 移除 # 号
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    // 验证格式：6位或8位十六进制
    if (hex.length != 6 && hex.length != 8) {
      return null;
    }

    // 检查是否都是有效的十六进制字符
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(hex)) {
      return null;
    }

    try {
      if (hex.length == 6) {
        // RGB: #RRGGBB
        return Color(int.parse('FF$hex', radix: 16));
      } else {
        // ARGB: #AARRGGBB
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      return null;
    }
  }
}
