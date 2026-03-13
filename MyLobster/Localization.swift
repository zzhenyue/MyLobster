//
//  Localization.swift
//  MyLobster
//
//  All user-visible strings in one place.
//  Default language is Chinese (zh). Toggle to English (en) via the title screen.
//

import Foundation

// MARK: - Language

enum AppLanguage: String {
    case zh = "zh"
    case en = "en"
}

// MARK: - String table

struct L {
    let lang: AppLanguage

    // ── Title Screen ──────────────────────────────────────────────────────────
    var appTitle:    String { zh("开放龙虾", "OPEN LOBSTER") }
    var selectMode:  String { zh("选择模式", "SELECT MODE") }
    var playButton:  String { zh("[ 开始 ]", "[ PLAY ]") }

    // Mode tiles
    var chainTitle:    String { zh("逃脱", "ESCAPE") }
    var chainSubtitle: String { zh("吃饱喝足\n挣脱锁链", "Eat 30.\nBreak free.") }
    var survivalTitle:    String { zh("生存", "SURVIVAL") }
    var survivalSubtitle: String { zh("无限进食\n越长越大", "Eat forever.\nGrow huge.") }

    // ── Game Scene HUD ────────────────────────────────────────────────────────
    var pauseLabel:   String { zh("暂停", "PAUSE") }
    var resumeLabel:  String { zh("继续", "RESUME") }
    var quitLabel:    String { zh("退出", "QUIT")   }
    var pausedTitle:  String { zh("已暂停", "PAUSED") }
    var bestLabel:    String { zh("最佳", "BEST")   }
    var nowLabel:     String { zh("当前", "NOW")    }
    var noBest:       String { zh("--",   "--")     }

    // Feedback flashes
    var nomText:     String { zh("好吃!", "NOM!") }
    var missText:    String { zh("错过!", "MISS!")    }
    var caughtText:  String { zh("接住!", "CAUGHT!")  }
    var savedText:   String { zh("安全!", "SAVED!")   }
    var bletchText:  String { zh("呕！", "BLECH!") }
    var boomText:    String { zh("爆炸!", "BOOM!")    }
    var freeText:    String { zh("自由啦!!!", "FREE!!!") }
    var goodbyeText: String { zh("谢谢，拜拜！", "THANK YOU, GOODBYE!") }
    var survivalBadge: String { zh("生存模式", "SURVIVAL") }
    var chainLabel:  String { zh("进度", "PROGRESS")    }

    
    // Tutorial overlay prompts (step-by-step first-play guide)
    var tutFoodPrompt:    String { zh("向下滑动吃掉食物！", "Swipe DOWN to eat food!") }
    var tutGarbagePrompt: String { zh("向右滑动收集垃圾！", "Swipe RIGHT to collect garbage!") }
    var tutBombPrompt:    String { zh("向左滑动处理炸弹！", "Swipe LEFT to handle bomb!") }
    var tutPausePrompt:   String { zh("点击龙虾暂停游戏！", "Tap the lobster to pause!") }
    var tutResumePrompt:  String { zh("就是这样！点击继续。", "That's it! Tap to resume.") }
    var tutTryIt:         String { zh("试一试！", "Try it!") }

    // ── Result Screen ─────────────────────────────────────────────────────────
    var youBrokeFree:   String { zh("你自由了！",  "YOU BROKE FREE!") }
    var bombHit:        String { zh("被炸弹炸到！", "BOMB HIT!")      }
    var chainMode:      String { zh("锁链模式",   "CHAIN MODE")    }
    var survivalMode:   String { zh("生存模式",   "SURVIVAL MODE") }
    var newBest:        String { zh("新纪录！",   "NEW PERSONAL BEST!") }
    var completionTime: String { zh("完成时间",   "COMPLETION TIME") }
    var foodEatenLabel: String { zh("吃了多少食物",   "FOOD EATEN")    }
    var foodEatenBest:  String { zh("最好成绩", "PERSONAL BEST") }
    var trashEaten:     String { zh("吃了多少垃圾", "TRASH EATEN")   }
    var bestTime:       String { zh("最短用时",   "PERSONAL BEST")     }
    var bestFood:       String { zh("最好成绩",   "PERSONAL BEST")     }
    var playAgain:      String { zh("[ 再来一次 ]", "[ PLAY AGAIN ]") }
    var backToMenu:     String { zh("[ 返回主菜单 ]", "[ BACK TO MENU ]") }

    // MARK: - Private helper
    private func zh(_ chinese: String, _ english: String) -> String {
        lang == .zh ? chinese : english
    }
}
