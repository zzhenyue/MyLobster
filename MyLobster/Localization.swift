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
    var appTitle:    String { zh("我的龙虾", "MY LOBSTER") }
    var tagline:     String { zh("喂食。成长。逃脱。", "FEED. GROW. ESCAPE.") }
    var selectMode:  String { zh("选择模式", "SELECT MODE") }
    var playButton:  String { zh("[ 开始 ]", "[ PLAY ]") }

    // Mode tiles
    var chainTitle:    String { zh("锁链", "CHAIN") }
    var chainSubtitle: String { zh("吃30个\n挣脱锁链", "Eat 30.\nBreak free.") }
    var survivalTitle:    String { zh("生存", "SURVIVAL") }
    var survivalSubtitle: String { zh("无限进食\n越长越大", "Eat forever.\nGrow huge.") }

    // Control badges
    var food:    String { zh("食物",   "FOOD")  }
    var trash:   String { zh("垃圾",   "TRASH") }
    var bomb:    String { zh("炸弹",   "BOMB")  }
    var eatSwipe:   String { zh("↓ 吃",    "↓ EAT")   }
    var netSwipe:   String { zh("→ 网",    "→ NET")   }
    var handSwipe:  String { zh("← 接",    "← HAND")  }
    var foodMiss:   String { zh("↑←→ 错过", "↑←→ MISS") }
    var trashMiss:  String { zh("其他 = -1", "OTHER = -1") }
    var bombMiss:   String { zh("其他 = 爆炸", "OTHER = BOOM") }
    var warning:    String { zh("垃圾减进度 • 错接炸弹即死！", "Trash = lose progress  •  Wrong bomb = instant death!") }

    // ── Game Scene HUD ────────────────────────────────────────────────────────
    var pauseLabel:   String { zh("暂停", "PAUSE") }
    var resumeLabel:  String { zh("继续", "RESUME") }
    var quitLabel:    String { zh("退出", "QUIT")   }
    var pausedTitle:  String { zh("已暂停", "PAUSED") }
    var bestLabel:    String { zh("最佳", "BEST")   }
    var nowLabel:     String { zh("当前", "NOW")    }
    var noBest:       String { zh("--",   "--")     }

    // Feedback flashes
    var nomText:     String { zh("+1 好吃!", "+1 NOM!") }
    var missText:    String { zh("错过!", "MISS!")    }
    var caughtText:  String { zh("接住!", "CAUGHT!")  }
    var savedText:   String { zh("安全!", "SAVED!")   }
    var bletchText:  String { zh("呕！-1", "BLECH! -1") }
    var boomText:    String { zh("爆炸!", "BOOM!")    }
    var freeText:    String { zh("自由啦!!!", "FREE!!!") }
    var goodbyeText: String { zh("谢谢，再见！", "THANK YOU, GOODBYE!") }
    var chainedText: String { zh("被锁", "CHAINED")  }
    var survivalBadge: String { zh("生存模式", "SURVIVAL") }
    var chainLabel:  String { zh("锁链", "CHAIN")    }

    // Hint labels
    var hintFood:    String { zh("向下滑动吃食！", "SWIPE DOWN to eat!") }
    var hintGarbage: String { zh("向右滑动 → 网接！", "SWIPE RIGHT → net catches it!") }
    var hintBomb:    String { zh("向左滑动 ← 手接！", "SWIPE LEFT ← hand takes it!") }

    // ── Result Screen ─────────────────────────────────────────────────────────
    var youBrokeFree:   String { zh("你自由了！",  "YOU BROKE FREE!") }
    var bombHit:        String { zh("被炸弹炸到！", "BOMB HIT!")      }
    var chainMode:      String { zh("锁链模式",   "CHAIN MODE")    }
    var survivalMode:   String { zh("生存模式",   "SURVIVAL MODE") }
    var newBest:        String { zh("新纪录！",   "NEW PERSONAL BEST!") }
    var completionTime: String { zh("完成时间",   "COMPLETION TIME") }
    var foodEatenLabel: String { zh("吃了多少",   "FOOD EATEN")    }
    var foodEatenBest:  String { zh("最多吃了多少", "FOOD EATEN (BEST)") }
    var trashEaten:     String { zh("吃了多少垃圾", "TRASH EATEN")   }
    var causeDeath:     String { zh("死亡原因",   "CAUSE OF DEATH") }
    var bombCause:      String { zh("炸弹",      "BOMB")          }
    var bestTime:       String { zh("最佳时间",   "BEST TIME")     }
    var bestFood:       String { zh("最多食物",   "BEST FOOD")     }
    var playAgain:      String { zh("[ 再来一次 ]", "[ PLAY AGAIN ]") }
    var backToMenu:     String { zh("[ 返回主菜单 ]", "[ BACK TO MENU ]") }

    // MARK: - Private helper
    private func zh(_ chinese: String, _ english: String) -> String {
        lang == .zh ? chinese : english
    }
}
