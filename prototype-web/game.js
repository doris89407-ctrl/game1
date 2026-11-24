(() => {
  const $ = (selector) => document.querySelector(selector);
  const screens = ["home", "warmup", "game", "review", "summary"];
  const state = {
    stage: 0,
    selected: -1,
    mistakes: [0, 0],
    hintUsed: [false, false],
    scores: [0, 0],
    warmup: [],
    review: [],
    quizIndex: 0,
    quizChoice: -1,
    quizLocked: false,
    sound: false,
    audio: null,
  };

  const stages = [
    {
      number: "01",
      name: "星星銀行",
      title: "先照顧需要，再留一點星星",
      story: "夢門前有 10 顆星星。小夢魔需要一個書包（4 顆）和一份午餐（3 顆），也想買玩具（3 顆）。哪個安排最穩妥？",
      hint: "先把每天需要的東西放進計畫，再為目標存一些，最後留一點預備金。想要的東西可以等一等。",
      choices: [
        "買書包和午餐，再買玩具；今天全部用完。",
        "買書包和午餐，存下 2 顆，還留 1 顆應付臨時需要。",
        "把 10 顆都存起來，今天不吃午餐也不帶書包。",
      ],
      answer: 1,
      success: "安排得很棒！先顧好需要，為目標儲蓄，也留一點預備金。玩具可以等下次有計畫時再買。",
    },
    {
      number: "02",
      name: "月光市集",
      title: "把風險分散，別忘了預備金",
      story: "你有 10 顆星星，其中 2 顆要留作緊急預備金。剩下 8 顆想支持兩家小店。哪種做法不會把希望全押在一處？",
      hint: "每家小店的生意都可能變好或變差。分散選擇能降低單一事件帶來的影響，預備金也不拿去投資。",
      choices: [
        "8 顆全放進最近最紅的店，再把預備金也加進去。",
        "兩家各放 4 顆，另外 2 顆保留；記得生意和價值仍可能變動。",
        "8 顆全放在第一家店，因為認識老闆就保證不會虧。",
      ],
      answer: 1,
      success: "你沒有把星星全押在一家店，也保留了預備金。分散能減少單一變化的影響，但不能保證不會虧損。",
    },
  ];

  const quizItems = [
    {
      prompt: "如果手上的零用錢有限，哪個安排最能同時照顧需要和未來目標？",
      choices: [
        "先買最想要的新玩具，其他事情以後再說。",
        "先安排每天需要的午餐，再留一部分儲蓄，最後才看有沒有錢買想要的東西。",
        "把全部零用錢都花掉，這樣就不用想怎麼分配。",
      ],
      answer: 1,
      explain: "先分清需要和想要，安排必要支出，再儲蓄和留預備金。",
    },
    {
      prompt: "如果想支持小店、但不知道哪家下個月生意更好，可以怎麼想？",
      choices: [
        "全部放在最紅的店，因為紅就代表一定賺。",
        "分散選擇，保留急用的錢，並記得結果可能好也可能不好。",
        "只要認識店老闆，投入多少都不會有風險。",
      ],
      answer: 1,
      explain: "分散選擇可以降低單一事件的影響，但投資仍有風險，沒有保證獲利。",
    },
  ];

  function showScreen(id) {
    screens.forEach((screen) => {
      const element = document.getElementById(screen);
      const active = screen === id;
      element.hidden = !active;
      element.classList.toggle("active", active);
    });
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function playTone(kind = "success") {
    if (!state.sound) return;
    try {
      state.audio ||= new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = state.audio.createOscillator();
      const gain = state.audio.createGain();
      oscillator.type = "sine";
      oscillator.frequency.value = kind === "success" ? 660 : kind === "wrong" ? 210 : 440;
      gain.gain.setValueAtTime(0.055, state.audio.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, state.audio.currentTime + 0.24);
      oscillator.connect(gain).connect(state.audio.destination);
      oscillator.start();
      oscillator.stop(state.audio.currentTime + 0.25);
    } catch (_) {
      // Sound is optional; the game remains fully playable if audio is unavailable.
    }
  }

  function toast(message) {
    const element = $("#toast");
    element.textContent = message;
    element.classList.add("show");
    window.clearTimeout(toast.timer);
    toast.timer = window.setTimeout(() => element.classList.remove("show"), 2600);
  }

  function startWarmup() {
    state.stage = 0;
    state.mistakes = [0, 0];
    state.hintUsed = [false, false];
    state.scores = [0, 0];
    state.warmup = [];
    state.review = [];
    state.quizIndex = 0;
    state.quizChoice = -1;
    state.quizLocked = false;
    renderQuiz("warmup");
    showScreen("warmup");
  }

  function renderQuiz(kind) {
    const isReview = kind === "review";
    const item = quizItems[state.quizIndex];
    const question = document.getElementById(`${kind}-question`);
    const progress = document.getElementById(`${kind}-progress`);
    const feedback = document.getElementById(`${kind}-feedback`);
    const next = document.getElementById(`${kind}-next`);
    progress.innerHTML = quizItems.map((_, index) => `<i class="${index <= state.quizIndex ? "done" : ""}"></i>`).join("");
    question.innerHTML = `<h2>${item.prompt}</h2><div class="question-options">${item.choices.map((choice, index) => `<button type="button" class="answer-option" data-answer="${index}" aria-pressed="false"><span class="option-mark">${String.fromCharCode(65 + index)}</span><span>${choice}</span></button>`).join("")}</div>`;
    feedback.textContent = "";
    feedback.className = "feedback";
    next.disabled = true;
    next.textContent = state.quizIndex === quizItems.length - 1
      ? (isReview ? "看我的冒險成果" : "進入第一段夢境")
      : "繼續";
    question.querySelectorAll("[data-answer]").forEach((button) => {
      button.addEventListener("click", () => {
        if (state.quizLocked) return;
        state.quizChoice = Number(button.dataset.answer);
        question.querySelectorAll("[data-answer]").forEach((option) => {
          option.classList.toggle("selected", option === button);
          option.setAttribute("aria-pressed", String(option === button));
        });
        const correct = state.quizChoice === item.answer;
        if (isReview) state.review[state.quizIndex] = correct;
        else state.warmup[state.quizIndex] = correct;
        feedback.textContent = isReview
          ? `${correct ? "答對了！" : "這次沒有選中最合適的做法。"}${item.explain}`
          : "已記下你的想法。完成夢境後會再回答一次，看看新學到什麼。";
        feedback.className = `feedback ${isReview && correct ? "good" : ""}`;
        next.disabled = false;
        playTone(correct ? "success" : "wrong");
      });
    });
  }

  function advanceQuiz(kind) {
    if (state.quizIndex < quizItems.length - 1) {
      state.quizIndex += 1;
      state.quizChoice = -1;
      renderQuiz(kind);
      return;
    }
    if (kind === "warmup") {
      state.quizIndex = 0;
      beginStage(0);
      showScreen("game");
    } else {
      finishGame();
    }
  }

  function beginStage(index) {
    state.stage = index;
    state.selected = -1;
    const stage = stages[index];
    $("#stage-kicker").textContent = `夢境 ${stage.number}`;
    $("#stage-title").textContent = stage.name;
    $("#stage-score").textContent = "100";
    $("#challenge-counter").textContent = `互動單元 ${stage.number} / 02`;
    $("#challenge-title").textContent = stage.title;
    $("#challenge-story").textContent = stage.story;
    $("#key-indicator").textContent = "✦ 尚未取得鑰匙";
    $("#key-indicator").classList.remove("acquired");
    $("#scene-image").classList.toggle("market", index === 1);
    $("#scene-image").setAttribute("aria-label", index === 1 ? "月光市集裡的星星小店與夢門" : "巨大星星銀行的齒輪大廳");
    $("#scene-subtitle").textContent = index === 0 ? "讀懂星星的用途，夢門就會亮起。" : "每一間小店都藏著未知的明天。";
    $("#game-feedback").textContent = "";
    $("#game-feedback").className = "feedback";
    $("#hint-button").hidden = false;
    $("#hint-button").disabled = false;
    $("#hint-button").innerHTML = "給我一點提示 <span aria-hidden=\"true\">◌</span>";
    $("#submit-answer").hidden = false;
    $("#submit-answer").disabled = true;
    $("#continue-button").hidden = true;
    $("#key-one").classList.toggle("acquired", index > 0);
    $("#key-two").classList.remove("acquired");
    $("#choice-list").innerHTML = stage.choices.map((choice, option) => `<button type="button" class="choice" data-choice="${option}" aria-pressed="false"><span class="option-mark">${String.fromCharCode(65 + option)}</span><span>${choice}</span></button>`).join("");
    $("#choice-list").querySelectorAll("[data-choice]").forEach((button) => button.addEventListener("click", () => selectChoice(Number(button.dataset.choice))));
    showScreen("game");
  }

  function selectChoice(index) {
    const choices = $("#choice-list").querySelectorAll("[data-choice]");
    if (choices[0]?.disabled) return;
    state.selected = index;
    choices.forEach((button, option) => {
      button.classList.toggle("selected", option === index);
      button.setAttribute("aria-pressed", String(option === index));
    });
    $("#submit-answer").disabled = false;
  }

  function useHint() {
    if (state.hintUsed[state.stage]) return;
    state.hintUsed[state.stage] = true;
    $("#stage-score").textContent = String(Math.max(40, 100 - state.mistakes[state.stage] * 20 - 10));
    $("#game-feedback").textContent = `提示：${stages[state.stage].hint}（使用提示，本關最多得 90 分。）`;
    $("#game-feedback").className = "feedback";
    $("#hint-button").disabled = true;
    $("#hint-button").textContent = "已使用提示";
    playTone("hint");
  }

  function submitAnswer() {
    if (state.selected < 0) return;
    const stage = stages[state.stage];
    const feedback = $("#game-feedback");
    if (state.selected !== stage.answer) {
      state.mistakes[state.stage] += 1;
      const score = Math.max(40, 100 - state.mistakes[state.stage] * 20 - (state.hintUsed[state.stage] ? 10 : 0));
      $("#stage-score").textContent = String(score);
      feedback.textContent = `這個安排還有一點可以再想想。分數先保留 ${score} 分，試著看看哪些是需要、哪些是想要。`;
      feedback.className = "feedback bad";
      playTone("wrong");
      return;
    }
    state.scores[state.stage] = Math.max(40, 100 - state.mistakes[state.stage] * 20 - (state.hintUsed[state.stage] ? 10 : 0));
    $("#stage-score").textContent = String(state.scores[state.stage]);
    $("#key-indicator").textContent = "✦ 已取得鑰匙";
    $("#key-indicator").classList.add("acquired");
    $("#game-feedback").textContent = stage.success;
    $("#game-feedback").className = "feedback good";
    $("#choice-list").querySelectorAll("[data-choice]").forEach((button, index) => {
      button.disabled = true;
      if (index === stage.answer) button.classList.add("correct");
    });
    $("#submit-answer").hidden = true;
    $("#hint-button").hidden = true;
    $("#continue-button").hidden = false;
    $("#continue-button").textContent = state.stage === 0 ? "收下鑰匙，前往月光市集" : "收下鑰匙，看看成長成果";
    $(`#key-${state.stage === 0 ? "one" : "two"}`).classList.add("acquired");
    playTone("success");
  }

  function moveForward() {
    if (state.stage === 0) {
      beginStage(1);
      return;
    }
    state.quizIndex = 0;
    state.quizChoice = -1;
    state.quizLocked = false;
    renderQuiz("review");
    showScreen("review");
  }

  function finishGame() {
    $("#final-score-one").textContent = state.scores[0];
    $("#final-score-two").textContent = state.scores[1];
    const before = state.warmup.filter(Boolean).length * 50;
    const after = state.review.filter(Boolean).length * 50;
    const progress = after - before;
    $("#progress-score").textContent = `${progress > 0 ? "+" : ""}${progress}`;
    $("#progress-detail").textContent = progress > 0
      ? `暖身 ${before}% → 回顧 ${after}%，你多答對了 ${progress / 50} 題。`
      : progress === 0
        ? `暖身 ${before}% → 回顧 ${after}%，你的想法保持穩定。`
        : `暖身 ${before}% → 回顧 ${after}%，下次可以再練習一次。`;
    $("#progress-fill").style.width = `${after}%`;
    $("#lesson-one").textContent = state.scores[0] >= 80 ? "你學會先顧需要、再儲蓄和留預備金。" : "再練習把需要、想要和儲蓄分開安排。";
    $("#lesson-two").textContent = state.scores[1] >= 80 ? "你知道分散能降低單一變化的影響，但不保證獲利。" : "記得分散選擇，並為投資保留風險空間。";
    try {
      const previous = JSON.parse(localStorage.getItem("little-dream-score") || "null");
      const record = { scores: [...state.scores], before, after, date: new Date().toISOString() };
      if (!previous || state.scores[0] + state.scores[1] >= previous.scores.reduce((sum, value) => sum + value, 0)) {
        localStorage.setItem("little-dream-score", JSON.stringify(record));
      }
    } catch (_) { /* Storage is optional; this session still reports its own results. */ }
    showScreen("summary");
    playTone("success");
  }

  function copyResult() {
    const before = state.warmup.filter(Boolean).length * 50;
    const after = state.review.filter(Boolean).length * 50;
    const progress = after - before;
    const text = `小小夢魔冒險成果：需要與儲蓄 ${state.scores[0]} 分；分散與風險 ${state.scores[1]} 分；理財想法 ${before}% → ${after}%（${progress > 0 ? "+" : ""}${progress} 個百分點）。`;
    if (!navigator.clipboard?.writeText) {
      toast(text);
      return;
    }
    navigator.clipboard.writeText(text).then(() => toast("成果已複製，可以分享給老師或家人！")).catch(() => toast(text));
  }

  $("#start-button").addEventListener("click", startWarmup);
  $("#warmup-next").addEventListener("click", () => advanceQuiz("warmup"));
  $("#review-next").addEventListener("click", () => advanceQuiz("review"));
  $("#submit-answer").addEventListener("click", submitAnswer);
  $("#hint-button").addEventListener("click", useHint);
  $("#continue-button").addEventListener("click", moveForward);
  $("#play-again").addEventListener("click", startWarmup);
  $("#copy-result").addEventListener("click", copyResult);
  $("#home-button").addEventListener("click", () => showScreen("home"));
  $("#sound-toggle").addEventListener("click", (event) => {
    state.sound = !state.sound;
    event.currentTarget.setAttribute("aria-pressed", String(state.sound));
    event.currentTarget.querySelector("span").textContent = `音效${state.sound ? "開" : "關"}`;
    toast(state.sound ? "已開啟簡短提示音。" : "音效已關閉。遊戲文字提示仍會保留。");
    playTone("hint");
  });
  document.addEventListener("keydown", (event) => {
    const gameActive = !$("#game").hidden;
    if (!gameActive || !/^[1-3]$/.test(event.key)) return;
    selectChoice(Number(event.key) - 1);
  });
})();
