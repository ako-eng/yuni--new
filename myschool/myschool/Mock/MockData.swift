import Foundation

enum MockData {

    static let currentUser = UserProfile(
        id: "u001",
        name: "张明远",
        studentId: "2024010101",
        department: "计算机科学与技术学院",
        major: "软件工程",
        grade: "大三",
        avatarName: "person.crop.circle.fill"
    )

    static let currentWeek = 12

    // MARK: - Notices

    static let notices: [Notice] = [
        Notice(id: "n001",
               title: "关于2026年春季学期期末考试安排的通知",
               summary: "2025-2026学年第二学期期末考试将于6月20日至7月5日进行，请各位同学做好复习准备。",
               content: "各学院、各位同学：\n\n2025-2026学年第二学期期末考试将于6月20日至7月5日进行。请各位同学合理安排复习时间，按时参加考试。\n\n具体考试安排请登录教务系统查询。如有课程冲突，请于6月10日前向学院教务办提出调整申请。\n\n祝大家取得好成绩！",
               category: .exam, source: "教务处",
               publishDate: date(daysAgo: 0),
               isRead: false, isImportant: true, isUrgent: true, attachments: ["附件"]),

        Notice(id: "n002",
               title: "第十二届全国大学生数学竞赛报名通知",
               summary: "全国大学生数学竞赛开始报名，请感兴趣的同学于4月15日前完成报名。",
               content: "各位同学：\n\n第十二届全国大学生数学竞赛现已开放报名。本次竞赛分为数学类和非数学类两个组别，欢迎各专业同学踊跃参加。\n\n报名截止日期：2026年4月15日\n报名方式：登录学院官网竞赛报名系统\n\n如有疑问，请联系理学院竞赛办公室。",
               category: .competition, source: "理学院",
               publishDate: date(daysAgo: 1),
               isRead: false, isImportant: true, isUrgent: false, attachments: []),

        Notice(id: "n003",
               title: "图书馆清明节期间开放时间调整通知",
               summary: "清明节假期图书馆开放时间调整为9:00-17:00，请合理安排借阅时间。",
               content: "各位读者：\n\n清明节假期（4月4日-4月6日）期间，图书馆开放时间调整如下：\n\n主馆：9:00-17:00\n自习室：8:00-22:00\n电子阅览室：关闭\n\n4月7日起恢复正常开放时间。",
               category: .library, source: "图书馆",
               publishDate: date(daysAgo: 1),
               isRead: true, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n004",
               title: "关于开展2026年大学生创新创业训练计划项目申报的通知",
               summary: "2026年大创项目开始申报，每个项目资助经费最高2万元。",
               content: "各学院、各位同学：\n\n2026年大学生创新创业训练计划项目现已开始申报。本年度计划立项国家级项目30项、省级项目60项、校级项目120项。\n\n申报截止日期：2026年4月30日\n资助标准：国家级2万元/项、省级1万元/项、校级5000元/项",
               category: .research, source: "科研处",
               publishDate: date(daysAgo: 2),
               isRead: false, isImportant: true, isUrgent: false, attachments: ["附件"]),

        Notice(id: "n005",
               title: "校园网络升级维护通知",
               summary: "本周六凌晨2:00-6:00将进行校园网络升级维护，届时网络将暂时中断。",
               content: "各位师生：\n\n为提升校园网络服务质量，信息中心将于本周六（3月29日）凌晨2:00-6:00进行网络升级维护。届时校园网将暂时中断，请提前做好准备。\n\n给您带来不便，敬请谅解。",
               category: .logistics, source: "信息中心",
               publishDate: date(daysAgo: 2),
               isRead: true, isImportant: false, isUrgent: true, attachments: []),

        Notice(id: "n006",
               title: "2026年春季校园招聘会通知",
               summary: "50余家知名企业将参加本次春季校园招聘会，欢迎应届毕业生参加。",
               content: "各位同学：\n\n2026年春季校园招聘会将于4月12日（周六）9:00-16:00在体育馆举行。本次招聘会共有50余家知名企业参加，提供岗位涵盖计算机、电子、机械、金融等多个领域。\n\n请携带简历和学生证参加。",
               category: .enterprise, source: "就业指导中心",
               publishDate: date(daysAgo: 3),
               isRead: false, isImportant: true, isUrgent: false, attachments: ["附件"]),

        Notice(id: "n007",
               title: "关于加强校园电动车管理的通知",
               summary: "即日起校园内电动车须统一登记挂牌，未登记车辆将禁止入校。",
               content: "各位师生：\n\n为加强校园交通安全管理，自即日起所有在校园内使用的电动车须到保卫处统一登记挂牌。\n\n登记时间：工作日 9:00-11:30, 14:00-16:30\n登记地点：保卫处办公室（行政楼B102）\n\n未按规定登记的电动车将禁止进入校园。",
               category: .security, source: "保卫处",
               publishDate: date(daysAgo: 3),
               isRead: true, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n008",
               title: "食堂新增菜品及营业时间调整公告",
               summary: "第二食堂新增夜宵档口，营业时间延长至晚上10点。",
               content: "各位同学：\n\n为更好地服务广大师生，第二食堂将于本周起新增夜宵档口，营业时间延长至晚上22:00。新增菜品包括各类小吃、面食和饮品。\n\n欢迎大家前来品尝！",
               category: .life, source: "后勤集团",
               publishDate: date(daysAgo: 4),
               isRead: false, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n009",
               title: "关于做好2025-2026学年第二学期补退选课工作的通知",
               summary: "补退选课将于3月31日开始，请需要调整课程的同学及时操作。",
               content: "各学院、各位同学：\n\n2025-2026学年第二学期补退选课工作将于3月31日至4月4日进行。请需要调整课表的同学登录教务系统完成操作。\n\n注意事项：\n1. 退课操作不可撤销\n2. 选课以先到先得为原则\n3. 必修课退课需学院审批",
               category: .academic, source: "教务处",
               publishDate: date(daysAgo: 4),
               isRead: false, isImportant: true, isUrgent: false, attachments: []),

        Notice(id: "n010",
               title: "第八届\"互联网+\"大学生创新创业大赛校赛通知",
               summary: "校赛报名开始，获奖团队将推荐参加省赛和国赛。",
               content: "各学院、各位同学：\n\n第八届\"互联网+\"大学生创新创业大赛校赛现已启动。\n\n报名截止：2026年4月20日\n校赛时间：2026年5月中旬\n\n获得校赛一等奖的团队将推荐参加省赛。欢迎各专业同学组队参赛！",
               category: .competition, source: "创新创业学院",
               publishDate: date(daysAgo: 5),
               isRead: true, isImportant: false, isUrgent: false, attachments: ["附件"]),

        Notice(id: "n011",
               title: "关于2026年研究生学业奖学金评审工作的通知",
               summary: "2026年研究生学业奖学金评审工作即将开始，请符合条件的研究生提交申请材料。",
               content: "各研究生培养单位：\n\n2026年研究生学业奖学金评审工作即将启动，请各位研究生按照要求准备申请材料。\n\n提交截止日期：2026年4月10日",
               category: .academic, source: "研究生院",
               publishDate: date(daysAgo: 5),
               isRead: false, isImportant: false, isUrgent: false, attachments: ["附件"]),

        Notice(id: "n012",
               title: "实验室安全培训通知",
               summary: "所有进入实验室的同学必须完成安全培训并通过考核。",
               content: "各学院、各位同学：\n\n根据学校实验室安全管理规定，所有需要进入实验室开展实验的同学必须完成线上安全培训并通过考核。\n\n培训平台：实验室安全教育系统\n考核截止日期：2026年4月15日",
               category: .research, source: "实验室管理处",
               publishDate: date(daysAgo: 6),
               isRead: true, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n013",
               title: "校医院体检预约通知",
               summary: "2026年度学生体检开始预约，请各位同学按时完成体检。",
               content: "各位同学：\n\n2026年度学生健康体检即将开始，请各位同学登录校医院预约系统选择体检时间。\n\n体检时间：4月8日至4月30日\n体检地点：校医院2楼体检中心\n\n请空腹前往体检。",
               category: .life, source: "校医院",
               publishDate: date(daysAgo: 7),
               isRead: true, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n014",
               title: "ACM程序设计竞赛集训队选拔通知",
               summary: "ACM集训队招新选拔赛将于4月5日举行，欢迎编程爱好者报名。",
               content: "各位同学：\n\nACM程序设计竞赛集训队2026年选拔赛将于4月5日举行。\n\n比赛形式：个人赛，3小时5题\n比赛平台：校OJ系统\n报名方式：发送姓名+学号至acm@school.edu.cn",
               category: .competition, source: "计算机学院",
               publishDate: date(daysAgo: 8),
               isRead: false, isImportant: false, isUrgent: false, attachments: []),

        Notice(id: "n015",
               title: "关于暑期社会实践项目申报的通知",
               summary: "2026年暑期社会实践项目开始申报，鼓励学生深入基层开展调研。",
               content: "各学院、各位同学：\n\n2026年暑期社会实践项目现已开放申报。本年度重点支持乡村振兴、科技创新、文化传承等方向。\n\n申报截止：2026年5月15日\n资助标准：每支团队最高5000元",
               category: .general, source: "校团委",
               publishDate: date(daysAgo: 10),
               isRead: true, isImportant: false, isUrgent: false, attachments: ["附件"]),
    ]

    // MARK: - Courses

    static let courses: [Course] = [
        Course(id: "c001", name: "高等数学", teacher: "王建国", room: "教3-201", dayOfWeek: 1, startPeriod: 1, endPeriod: 2, colorIndex: 0, weeks: Array(1...16)),
        Course(id: "c002", name: "大学物理", teacher: "李明华", room: "教1-305", dayOfWeek: 1, startPeriod: 3, endPeriod: 4, colorIndex: 1, weeks: Array(1...16)),
        Course(id: "c003", name: "数据结构", teacher: "陈思远", room: "教2-101", dayOfWeek: 2, startPeriod: 1, endPeriod: 2, colorIndex: 2, weeks: Array(1...16)),
        Course(id: "c004", name: "线性代数", teacher: "赵文博", room: "教3-401", dayOfWeek: 2, startPeriod: 5, endPeriod: 6, colorIndex: 3, weeks: [1, 3, 5, 7, 9, 11, 13, 15]),
        Course(id: "c005", name: "大学英语", teacher: "Emily Chen", room: "外语楼203", dayOfWeek: 3, startPeriod: 1, endPeriod: 2, colorIndex: 4, weeks: Array(1...14)),
        Course(id: "c006", name: "计算机网络", teacher: "张海涛", room: "教2-301", dayOfWeek: 3, startPeriod: 3, endPeriod: 4, colorIndex: 5, weeks: Array(1...16)),
        Course(id: "c007", name: "概率论", teacher: "刘雅琴", room: "教1-201", dayOfWeek: 4, startPeriod: 1, endPeriod: 2, colorIndex: 6, weeks: Array(1...16)),
        Course(id: "c008", name: "操作系统", teacher: "周志强", room: "教2-501", dayOfWeek: 4, startPeriod: 5, endPeriod: 6, colorIndex: 7, weeks: [2, 4, 6, 8, 10, 12, 14, 16]),
        Course(id: "c009", name: "软件工程", teacher: "孙晓明", room: "教3-301", dayOfWeek: 5, startPeriod: 1, endPeriod: 2, colorIndex: 0, weeks: Array(1...16)),
        Course(id: "c010", name: "人工智能", teacher: "吴天宇", room: "教2-201", dayOfWeek: 5, startPeriod: 3, endPeriod: 4, colorIndex: 1, weeks: Array(3...16)),
        Course(id: "c011", name: "体育", teacher: "马老师", room: "体育馆", dayOfWeek: 3, startPeriod: 7, endPeriod: 8, colorIndex: 2, weeks: Array(1...14)),
    ]

    // MARK: - Grades

    static let grades: [GradeRecord] = [
        GradeRecord(id: "g001", courseName: "高等数学(上)", credit: 5.0, score: 92, gradePoint: 4.2, semester: "2025-2026-1"),
        GradeRecord(id: "g002", courseName: "程序设计基础", credit: 4.0, score: 95, gradePoint: 4.5, semester: "2025-2026-1"),
        GradeRecord(id: "g003", courseName: "大学英语(三)", credit: 2.0, score: 88, gradePoint: 3.8, semester: "2025-2026-1"),
        GradeRecord(id: "g004", courseName: "离散数学", credit: 3.0, score: 85, gradePoint: 3.5, semester: "2025-2026-1"),
        GradeRecord(id: "g005", courseName: "大学物理(上)", credit: 4.0, score: 90, gradePoint: 4.0, semester: "2025-2026-1"),
        GradeRecord(id: "g006", courseName: "思想政治理论", credit: 3.0, score: 82, gradePoint: 3.2, semester: "2025-2026-1"),
        GradeRecord(id: "g007", courseName: "线性代数", credit: 3.0, score: 78, gradePoint: 2.8, semester: "2024-2025-2"),
        GradeRecord(id: "g008", courseName: "数据结构", credit: 4.0, score: 91, gradePoint: 4.1, semester: "2024-2025-2"),
        GradeRecord(id: "g009", courseName: "计算机组成原理", credit: 3.5, score: 87, gradePoint: 3.7, semester: "2024-2025-2"),
        GradeRecord(id: "g010", courseName: "大学英语(二)", credit: 2.0, score: 90, gradePoint: 4.0, semester: "2024-2025-2"),
    ]

    // MARK: - Exams

    static let exams: [ExamInfo] = [
        ExamInfo(id: "e001", courseName: "高等数学", examDate: date(daysFromNow: 14), location: "教3-201", seatNumber: "A12"),
        ExamInfo(id: "e002", courseName: "数据结构", examDate: date(daysFromNow: 16), location: "教2-101", seatNumber: "B08"),
        ExamInfo(id: "e003", courseName: "大学物理", examDate: date(daysFromNow: 19), location: "教1-305", seatNumber: "C15"),
        ExamInfo(id: "e004", courseName: "计算机网络", examDate: date(daysFromNow: 22), location: "教2-301", seatNumber: "A23"),
        ExamInfo(id: "e005", courseName: "大学英语", examDate: date(daysFromNow: 25), location: "外语楼203", seatNumber: "D05"),
    ]

    // MARK: - Awards

    static let awards: [Award] = [
        Award(id: "a001", name: "全国大学生数学竞赛二等奖", level: .national, date: date(monthsAgo: 3), category: "学科竞赛"),
        Award(id: "a002", name: "省级\"互联网+\"创新创业大赛银奖", level: .provincial, date: date(monthsAgo: 5), category: "创新创业"),
        Award(id: "a003", name: "校级优秀学生奖学金", level: .school, date: date(monthsAgo: 6), category: "奖学金"),
        Award(id: "a004", name: "ACM程序设计竞赛区域赛铜奖", level: .provincial, date: date(monthsAgo: 8), category: "学科竞赛"),
        Award(id: "a005", name: "校级社会实践优秀个人", level: .school, date: date(monthsAgo: 10), category: "社会实践"),
    ]

    // MARK: - Search

    static let searchHistory = ["期末考试", "奖学金", "图书馆", "选课", "竞赛报名"]
    static let hotSearches = ["四六级报名", "研究生推免", "暑期实习", "学生会纳新", "校运动会"]

    // MARK: - Computed

    static var overallGPA: Double {
        let totalWeighted = grades.reduce(0.0) { $0 + $1.gradePoint * $1.credit }
        let totalCredits = grades.reduce(0.0) { $0 + $1.credit }
        return totalCredits > 0 ? totalWeighted / totalCredits : 0
    }

    static var nextExam: ExamInfo? {
        exams.filter { $0.daysUntil > 0 }.min { $0.examDate < $1.examDate }
    }

    // MARK: - Helpers

    private static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    private static func date(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }

    private static func date(monthsAgo: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -monthsAgo, to: Date()) ?? Date()
    }
}
