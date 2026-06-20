// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get menuTitle => '菜单';

  @override
  String get menuSignedIn => '已登录';

  @override
  String get menuSectionAccount => '账户';

  @override
  String get menuSectionPreferences => '偏好设置';

  @override
  String get menuSectionSecurity => '安全';

  @override
  String get menuSectionNotifications => '通知';

  @override
  String get menuSectionSupport => '支持';

  @override
  String get menuAccountDetails => '账户详情';

  @override
  String get menuSubscriptions => '订阅';

  @override
  String get menuPlanFree => '免费';

  @override
  String get menuAppearance => '外观';

  @override
  String get menuLanguage => '语言';

  @override
  String get menuChangePassword => '修改密码';

  @override
  String get menuBiometrics => '生物识别';

  @override
  String get menuPushNotifications => '推送通知';

  @override
  String get menuHelpSupport => '帮助与支持';

  @override
  String get menuAboutApp => '关于 Tickflow';

  @override
  String get menuSignOut => '退出登录';

  @override
  String get menuDeleteAccount => '删除账户';

  @override
  String get optionSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get biometricSetupHint => '请先在本设备上设置指纹或屏幕锁，才能使用生物识别解锁。';

  @override
  String get notificationsUpdateError => '无法更新通知设置';

  @override
  String get deleteAccountTitle => '删除账户？';

  @override
  String get deleteAccountBody => '这将永久删除您的账户、关注列表、投资组合、提醒和通知，且无法撤销。';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get deleteAccountError => '无法删除账户';

  @override
  String get commonGenericError => '出了点问题，请重试。';

  @override
  String get authTagline => '实时追踪美股';

  @override
  String get authEmail => '邮箱';

  @override
  String get authEnterEmail => '请输入邮箱';

  @override
  String get authInvalidEmail => '请输入有效的邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '至少 8 个字符';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authPasswordTooShort => '密码至少为 8 个字符';

  @override
  String get authCreateAccount => '注册账户';

  @override
  String get authSignIn => '登录';

  @override
  String get authToggleToSignIn => '已有账户？登录';

  @override
  String get authToggleToRegister => '还没有账户？注册';

  @override
  String get commonRetry => '重试';

  @override
  String get marketsTitle => '市场';

  @override
  String get marketsSearchHint => '搜索美股';

  @override
  String get marketsTabGainers => '涨幅榜';

  @override
  String get marketsTabLosers => '跌幅榜';

  @override
  String get marketsTabActive => '最活跃';

  @override
  String get marketsNoData => '暂无数据';

  @override
  String get favTitle => '自选';

  @override
  String get favEmptyTitle => '还没有自选股';

  @override
  String get favEmptyBody => '在「市场」中为股票点亮星标，它就会显示在这里并附带实时价格。';

  @override
  String favRemoveError(String symbol) {
    return '无法移除 $symbol';
  }

  @override
  String get portfolioTitle => '投资组合';

  @override
  String get portfolioAddHolding => '添加持仓';

  @override
  String get portfolioEmptyTitle => '还没有持仓';

  @override
  String get portfolioEmptyBody => '添加你持有的资产（数量和买入价），Tickflow 会为你跟踪市值和盈亏。';

  @override
  String get portfolioAddFirst => '添加第一笔持仓';

  @override
  String get portfolioTotalValue => '总市值';

  @override
  String get portfolioAnalytics => '分析';

  @override
  String get portfolioToday => '今日';

  @override
  String get portfolioCost => '成本';

  @override
  String get portfolioTotalGainLoss => '总盈亏';

  @override
  String get portfolioIncomplete => '部分持仓暂无实时价格，总计已将其排除。';

  @override
  String get portfolioHoldings => '持仓';

  @override
  String get portfolioDragToReorder => '拖动以重新排序';

  @override
  String get portfolioDone => '完成';

  @override
  String get portfolioEdit => '编辑';

  @override
  String get portfolioUnitShares => '股';

  @override
  String get portfolioUnitUnits => '单位';

  @override
  String portfolioHoldingSubtitle(String qty, String unit, String avg) {
    return '$qty $unit，平均 $avg';
  }

  @override
  String get portfolioCurrentLabel => '现价';

  @override
  String portfolioEditTitle(String symbol) {
    return '编辑 $symbol';
  }

  @override
  String get portfolioSymbol => '代码';

  @override
  String get portfolioSymbolHint => '美股代码，例如 AAPL';

  @override
  String get portfolioEnterSymbol => '请输入代码';

  @override
  String get portfolioQuantity => '数量';

  @override
  String get portfolioQtyError => '必须大于 0';

  @override
  String get portfolioBuyPrice => '买入价';

  @override
  String get portfolioPriceError => '必须大于或等于 0';

  @override
  String get portfolioSaveChanges => '保存更改';

  @override
  String get portfolioDeleteHolding => '删除持仓';

  @override
  String portfolioRemoveTitle(String symbol) {
    return '移除 $symbol？';
  }

  @override
  String get portfolioRemoveBody => '这会从你的投资组合中删除该持仓。';

  @override
  String get portfolioRemove => '移除';

  @override
  String get assetTypeStock => '股票';

  @override
  String get assetTypeEtf => 'ETF';

  @override
  String get assetTypeCrypto => '加密货币';
}
