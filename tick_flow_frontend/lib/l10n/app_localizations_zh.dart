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
  String get authForgotPassword => '忘记密码？';

  @override
  String get authForgotPasswordMsg =>
      '密码重置功能尚未开放。如需帮助，请发送邮件至 support@tickflow.my。';

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

  @override
  String get notifTitle => '通知';

  @override
  String get notifTabAlerts => '我的提醒';

  @override
  String get notifTabTriggered => '已触发';

  @override
  String get notifNewAlert => '新建提醒';

  @override
  String get alertsEmptyTitle => '还没有提醒';

  @override
  String get alertsEmptyBody => '当价格越过你设定的阈值时通知你。';

  @override
  String get alertsCreateFirst => '创建第一个提醒';

  @override
  String get alertRearm => '重新启用';

  @override
  String get alertRearmError => '无法重新启用该提醒';

  @override
  String get alertUpdateError => '无法更新该提醒';

  @override
  String get alertNow => '现价';

  @override
  String get alertPauseTooltip => '暂停提醒';

  @override
  String get alertResumeTooltip => '恢复提醒';

  @override
  String alertTriggeredCount(int count) {
    return '已触发 $count 次';
  }

  @override
  String get triggeredEmptyTitle => '暂无触发记录';

  @override
  String get triggeredEmptyBody => '当你的某个提醒触发时，会显示在这里。';

  @override
  String get alertRuleAbove => '高于';

  @override
  String get alertRuleBelow => '低于';

  @override
  String get alertKindOneShot => '一次性';

  @override
  String get alertKindReArm => '可重复';

  @override
  String get alertStatusActive => '已启用';

  @override
  String get alertStatusCooldown => '冷却中';

  @override
  String get alertStatusDone => '已完成';

  @override
  String get alertStatusPaused => '已暂停';

  @override
  String get alertSegPriceAbove => '价格高于';

  @override
  String get alertSegPriceBelow => '价格低于';

  @override
  String get alertHintAbove => '当价格高于阈值时触发。';

  @override
  String get alertHintBelow => '当价格低于阈值时触发。';

  @override
  String get alertKindOneShotDesc => '触发一次后会保留在历史记录中，直到重新启用。';

  @override
  String get alertKindReArmDesc => '触发后进入冷却，当价格回落时自动重新启用。';

  @override
  String get alertThreshold => '阈值';

  @override
  String get alertCreate => '创建提醒';

  @override
  String get alertNewTitle => '新建价格提醒';

  @override
  String alertEditTitle(String symbol) {
    return '编辑 $symbol 提醒';
  }

  @override
  String get alertDeleteButton => '删除提醒';

  @override
  String alertDeleteTitle(String symbol) {
    return '删除 $symbol 提醒？';
  }

  @override
  String alertDeleteContent(String rule, String threshold) {
    return '$rule $threshold —— 这也会将其从你的活动提醒历史中移除。';
  }

  @override
  String get navAlerts => '提醒';

  @override
  String get detailDailyBarsNote => '免费数据仅提供日线 ——「1D」大致显示最近一周。';

  @override
  String get detailNoChartData => '暂无图表数据';

  @override
  String get detailCachedChart => '正在显示缓存的图表数据';

  @override
  String get detailDelayed => '延迟';

  @override
  String get detailCached => '缓存';

  @override
  String detailChangeToday(String change, String percent) {
    return '$change（$percent）今日';
  }

  @override
  String get detailTodayTitle => '今日';

  @override
  String get detailStatOpen => '开盘';

  @override
  String get detailStatHigh => '最高';

  @override
  String get detailStatLow => '最低';

  @override
  String get detailStatPrevClose => '昨收';

  @override
  String get detailAbout => '关于';

  @override
  String get detailIndustry => '行业';

  @override
  String get detailExchange => '交易所';

  @override
  String get detailCountry => '国家/地区';

  @override
  String get detailMarketCap => '市值';

  @override
  String get detailIpo => 'IPO';

  @override
  String get detailWebsite => '网站';

  @override
  String get commonClear => '清除';

  @override
  String get searchHint => '搜索代码或公司';

  @override
  String get searchIdle => '按代码或公司名称搜索美股。';

  @override
  String searchNoMatches(String query) {
    return '没有与「$query」匹配的结果。';
  }

  @override
  String get accountUpdated => '资料已更新';

  @override
  String get accountEmailHint => '邮箱无法更改';

  @override
  String get accountDisplayName => '显示名称';

  @override
  String get accountDisplayNameHint => '显示在你的资料中 · 留空则使用邮箱';

  @override
  String get commonSave => '保存';

  @override
  String get changePwSuccess => '密码已修改';

  @override
  String get changePwCurrent => '当前密码';

  @override
  String get changePwCurrentError => '请输入当前密码';

  @override
  String get changePwNew => '新密码';

  @override
  String get changePwNewError => '新密码至少为 8 个字符';

  @override
  String get changePwConfirm => '确认新密码';

  @override
  String get changePwMismatch => '两次输入的密码不一致';

  @override
  String get commonComingSoon => '敬请期待';

  @override
  String get helpFaqsHeader => '常见问题';

  @override
  String get helpContactHeader => '联系我们';

  @override
  String get helpEmailUs => '给我们发邮件';

  @override
  String helpEmailCopied(String email) {
    return '$email 已复制到剪贴板';
  }

  @override
  String get helpLiveChat => '在线客服';

  @override
  String get helpReplyTime => '我们通常在 1–2 个工作日内回复。';

  @override
  String get helpFaqQ1 => '为什么我的报价有延迟？';

  @override
  String get helpFaqA1 =>
      '行情数据来自 Finnhub 和 Financial Modeling Prep。在免费数据层级，报价会有延迟，部分图表可能不可用。';

  @override
  String get helpFaqQ2 => '覆盖哪些市场？';

  @override
  String get helpFaqA2 => '目前为美国上市的股票和 ETF。更广泛的全球覆盖已在规划中 —— 详见订阅。';

  @override
  String get helpFaqQ3 => '如何添加持仓？';

  @override
  String get helpFaqA3 => '进入「投资组合」标签，点击 +，然后输入代码、数量和买入价。一切都会自动为你计算。';

  @override
  String get helpFaqQ4 => '价格提醒如何运作？';

  @override
  String get helpFaqA4 => '打开某个股票并点击「创建提醒」，或在「提醒」标签中添加。触发时会显示在你的应用内通知列表中。';

  @override
  String get helpFaqQ5 => '我的账户安全吗？';

  @override
  String get helpFaqA5 => '你的登录会话保存在设备的安全存储中。在移动端，你还可以在「菜单 → 安全」中开启生物识别。';

  @override
  String get plansOnFree => '你正在使用免费方案';

  @override
  String get plansSubtitle => 'Pro 上线后将解锁更多功能 —— 目前不收费。';

  @override
  String get plansBadgeCurrent => '当前';

  @override
  String get plansPriceMonth => '/月';

  @override
  String get plansFreeTagline => '追踪美股所需的一切。';

  @override
  String get plansFreeFeature1 => '美股和 ETF';

  @override
  String get plansFreeFeature2 => '实时（延迟）报价';

  @override
  String get plansFreeFeature3 => '自选和投资组合';

  @override
  String get plansFreeFeature4 => '价格提醒 + 通知列表';

  @override
  String get plansFreeFeature5 => '日线图表';

  @override
  String get plansCurrentPlan => '当前方案';

  @override
  String get plansProTagline => '实时追踪整个市场。';

  @override
  String get plansProFeature1 => '全球市场，不止美股';

  @override
  String get plansProFeature2 => '实时报价（无延迟）';

  @override
  String get plansProFeature3 => '日内图表和更长历史';

  @override
  String get plansProFeature4 => '无限提醒';

  @override
  String get plansProFeature5 => '优先支持';

  @override
  String get plansProNote => 'Pro 正在开发中 —— 这些功能尚不可用。';

  @override
  String get analyticsEstValueTitle => '估算价值';

  @override
  String get analyticsEstValueBody =>
      '此曲线根据每个持仓的每日收盘价（按当前数量）重建你的价值。没有历史价格的持仓 —— 加密货币以及数据提供商未覆盖的部分 ETF —— 不包含在内，因此可能与你的总市值不同。';

  @override
  String get analyticsGotIt => '知道了';

  @override
  String get analyticsPortfolioValue => '投资组合价值';

  @override
  String get analyticsChartUnavailable => '图表不可用';

  @override
  String get analyticsEstFromCloses => '根据每日收盘价估算';

  @override
  String get analyticsTopContributors => '主要贡献';

  @override
  String get analyticsQuickStats => '快速统计';

  @override
  String get analyticsLargestPosition => '最大持仓';

  @override
  String get analyticsAssetMix => '资产构成';

  @override
  String get analyticsEmpty => '添加持仓以查看分析。';

  @override
  String analyticsMixStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 股票',
    );
    return '$_temp0';
  }

  @override
  String analyticsMixEtf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ETF',
    );
    return '$_temp0';
  }

  @override
  String analyticsMixCrypto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 加密货币',
    );
    return '$_temp0';
  }

  @override
  String get allocationTitle => '占比';

  @override
  String get allocationByHolding => '按持仓';

  @override
  String get allocationByType => '按类型';

  @override
  String get allocationTapHint => '点击扇区查看';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get allocationOther => '其他';
}
