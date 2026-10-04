(() => {
  'use strict';

  const STATUS = {
    blocked: '応答待ち', idle: '待機中', working: '作業中',
    unknown: '状態不明', not_active: '非稼働'
  };
  const LIVE_ORDER = ['blocked', 'idle', 'working', 'unknown'];
  const POLL_MS = 5000;
  const TIMEOUT_MS = 8000;
  const state = {
    sessions: null, updatedAt: null, filter: 'all', query: '', scope: 'live', view: 'compact',
    selectedKey: null, messages: null, messagesPreview: false, previewHasSessionId: false,
    messagesLoading: false, messagesError: '',
    messagesTruncated: false, stale: false, warning: '', listError: '', focusError: '', focusing: false,
    loading: false, messageRequest: 0, lastMessageFetch: 0
  };

  const $ = (id) => document.getElementById(id);
  const list = $('session-list');
  const detail = $('detail-content');

  function node(tag, className, text) {
    const el = document.createElement(tag);
    if (className) el.className = className;
    if (text !== undefined) el.textContent = text;
    return el;
  }

  function value(input, fallback = '') {
    return typeof input === 'string' && input.trim() ? input.trim() : fallback;
  }

  function parseTimestamp(input) {
    if (typeof input !== 'number' && typeof input !== 'string') return null;
    const text = typeof input === 'string' ? input.trim() : input;
    if (text === '') return null;
    let date;
    if (typeof text === 'number' || /^-?\d+(?:\.\d+)?$/.test(text)) {
      const number = Number(text);
      if (!Number.isFinite(number)) return null;
      // 10桁前後の Unix 秒と13桁の Unix ミリ秒を区別する。
      date = new Date(Math.abs(number) < 1e11 ? number * 1000 : number);
    } else if (typeof text === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(text)) {
      date = new Date(text);
    } else {
      return null;
    }
    return Number.isFinite(date.getTime()) ? date : null;
  }

  function timeLabel(input) {
    const date = parseTimestamp(input);
    if (!date) return '時刻不明';
    const diff = Date.now() - date.getTime();
    if (diff >= 0 && diff < 60000) return 'たった今';
    if (diff >= 0 && diff < 3600000) return `${Math.floor(diff / 60000)}分前`;
    if (diff >= 0 && diff < 86400000) return `${Math.floor(diff / 3600000)}時間前`;
    return new Intl.DateTimeFormat('ja-JP', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' }).format(date);
  }

  function fullTime(input) {
    const date = parseTimestamp(input);
    return date
      ? new Intl.DateTimeFormat('ja-JP', { dateStyle: 'medium', timeStyle: 'short' }).format(date)
      : '時刻不明';
  }

  function knownStatus(input) { return Object.hasOwn(STATUS, input) ? input : 'unknown'; }
  function sessionName(session) { return value(session.title, value(session.session_id, 'タイトルなし')); }
  function workspaceName(session) { return value(session.workspace_label, value(session.workspace_id, value(session.cwd, 'ワークスペース不明'))); }
  function selectedSession() { return state.sessions?.find((session) => session.key === state.selectedKey); }
  function isLive(session) { return session.active === true && knownStatus(session.status) !== 'not_active'; }
  function scopeSessions() { return (state.sessions || []).filter((session) => state.scope === 'live' ? isLive(session) : !isLive(session)); }
  function recentFirst(a, b) {
    const aTime = parseTimestamp(a.updated_at)?.getTime() ?? -Infinity;
    const bTime = parseTimestamp(b.updated_at)?.getTime() ?? -Infinity;
    return bTime - aTime || a.key.localeCompare(b.key, 'ja');
  }
  function visibleSessions() {
    const query = state.query.toLocaleLowerCase();
    return scopeSessions().filter((session) => {
      if (state.scope === 'live' && state.filter !== 'all' && knownStatus(session.status) !== state.filter) return false;
      return !query || [session.title, session.agent, session.cwd, session.workspace_label, session.workspace_id, session.session_id]
        .some((part) => value(part).toLocaleLowerCase().includes(query));
    }).sort((a, b) => state.scope === 'live'
      ? LIVE_ORDER.indexOf(knownStatus(a.status)) - LIVE_ORDER.indexOf(knownStatus(b.status)) || recentFirst(a, b)
      : recentFirst(a, b));
  }

  async function getJSON(url, options = {}) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const response = await fetch(url, { cache: 'no-store', ...options, signal: controller.signal });
      let data;
      try { data = await response.json(); } catch { throw new Error('サーバーの応答を読み取れませんでした。'); }
      if (!response.ok || !data || typeof data !== 'object' || data.error) {
        throw new Error(value(data?.error, `通信に失敗しました（HTTP ${response.status}）。`));
      }
      return data;
    } finally {
      clearTimeout(timeout);
    }
  }

  function setSync() {
    const indicator = $('sync-indicator');
    indicator.className = `sync-indicator${state.stale ? ' stale' : state.warning ? ' partial' : state.loading ? ' loading' : ''}`;
    $('sync-text').textContent = state.stale
      ? `通信失敗 · ${state.updatedAt ? `履歴の最終取得 ${fullTime(state.updatedAt)}` : '履歴未取得'}`
      : state.loading && !state.sessions ? '読み込み中…'
      : state.warning ? `ライブ状態は未取得 · 履歴取得 ${fullTime(state.updatedAt)}`
      : state.loading ? '更新中…'
      : state.updatedAt ? `最終取得 ${fullTime(state.updatedAt)}` : '未取得';
    $('refresh-button').disabled = state.loading;
    const notice = $('list-notice');
    const noticeText = state.stale
      ? `${state.sessions ? '一覧を更新できませんでした。表示中の内容は古い可能性があります。' : '一覧を取得できませんでした。'}${state.listError}${state.warning ? ` 前回の履歴取得時: ${state.warning}` : ''}`
      : state.warning ? `ライブ状態を取得できていません。一覧の状態は最新とは限りませんが、履歴は閲覧できます。${state.warning}` : '';
    if (notice.textContent !== noticeText) notice.textContent = noticeText;
    notice.hidden = !noticeText;
    $('list-footnote').textContent = state.stale ? '自動で再接続を試みます'
      : state.warning ? '履歴を表示中 · 自動で再取得' : '数秒ごとに自動更新';
  }

  function renderSummary() {
    const sessions = state.sessions;
    const live = sessions?.filter(isLive);
    $('count-all').textContent = live ? String(live.length) : '—';
    $('history-count').textContent = live ? String(sessions.length - live.length) : '—';
    LIVE_ORDER.forEach((status) => {
      $(`count-${status}`).textContent = sessions
        ? String(live.filter((session) => knownStatus(session.status) === status).length) : '—';
    });
  }

  function makeRow(session) {
    const row = node('button', 'session-row');
    row.type = 'button';
    row.dataset.key = session.key;
    row.title = sessionName(session);
    row.setAttribute('aria-current', String(session.key === state.selectedKey));
    row.setAttribute('aria-label', `${sessionName(session)}、${value(session.agent, 'エージェント不明')}、${STATUS[knownStatus(session.status)]}、${workspaceName(session)}、${timeLabel(session.updated_at)}`);
    const main = node('span', 'row-main');
    main.append(node('span', 'agent-badge', value(session.agent, '?').slice(0, 1)));
    const name = node('span', 'row-name');
    name.append(node('span', 'row-title', sessionName(session)));
    const subtitle = state.scope === 'history' && state.view === 'grouped'
      ? value(session.cwd, value(session.agent, '場所不明'))
      : `${workspaceName(session)} · ${value(session.agent, 'エージェント不明')}`;
    name.append(node('span', 'row-subtitle', subtitle));
    main.append(name);
    const status = node('span', 'row-status');
    status.append(node('i', `status-dot ${knownStatus(session.status)}`), node('span', '', STATUS[knownStatus(session.status)]));
    status.firstChild.setAttribute('aria-hidden', 'true');
    row.append(main, status, node('span', 'row-time', timeLabel(session.updated_at)), node('span', 'row-arrow', '›'));
    row.lastChild.setAttribute('aria-hidden', 'true');
    row.addEventListener('click', () => selectSession(session.key));
    return row;
  }

  function renderList() {
    const focusedKey = document.activeElement?.classList?.contains('session-row') ? document.activeElement.dataset.key : null;
    const previousScroll = list.scrollTop;
    list.replaceChildren();
    const sessions = visibleSessions();
    const inScope = scopeSessions();
    $('visible-count').textContent = state.sessions ? `${sessions.length} / ${inScope.length}` : '';
    list.setAttribute('aria-busy', String(state.loading && !state.sessions));
    if (!state.sessions) {
      const empty = node('div', 'list-state');
      if (state.loading) {
        const glyph = node('span', 'loading-glyph');
        glyph.setAttribute('aria-hidden', 'true');
        empty.append(glyph, node('p', '', 'セッションを読み込んでいます…'));
      } else {
        empty.append(node('strong', '', '一覧を取得できませんでした'), node('p', '', state.listError || '接続を確認してください。'));
        const retry = node('button', 'retry-button', '再試行');
        retry.type = 'button';
        retry.addEventListener('click', loadSessions);
        empty.append(retry);
      }
      list.append(empty);
      return;
    }
    if (!sessions.length) {
      const empty = node('div', 'list-state');
      const hasSearchOrFilter = state.query || (state.scope === 'live' && state.filter !== 'all');
      empty.append(node('strong', '', hasSearchOrFilter ? '該当するセッションはありません'
        : state.scope === 'live' ? '稼働中のペインはありません' : 'セッション履歴はありません'),
      node('p', '', hasSearchOrFilter ? '検索語や絞り込みを変えてみてください。'
        : state.scope === 'live' && state.sessions.length > 0 ? '以前のセッションは「セッション履歴」から確認できます。'
        : 'セッションが見つかると、ここに表示されます。'));
      list.append(empty);
    } else if (state.scope === 'live') {
      for (const status of LIVE_ORDER) {
        const items = sessions.filter((session) => knownStatus(session.status) === status);
        if (!items.length) continue;
        const heading = node('div', `group-heading status-heading ${status}`);
        const dot = node('i', `status-dot ${status}`);
        dot.setAttribute('aria-hidden', 'true');
        heading.append(dot, node('span', 'group-name', STATUS[status]), node('span', 'group-count', String(items.length)));
        list.append(heading);
        items.forEach((session) => { list.append(makeRow(session)); });
      }
    } else if (state.view === 'grouped') {
      const groups = new Map();
      sessions.forEach((session) => {
        const id = value(session.workspace_id, value(session.workspace_label, value(session.cwd, '')));
        if (!groups.has(id)) groups.set(id, []);
        groups.get(id).push(session);
      });
      for (const group of groups.values()) {
        const heading = node('div', 'group-heading');
        heading.append(node('span', 'group-name', workspaceName(group[0])), node('span', 'group-count', String(group.length)));
        list.append(heading);
        group.forEach((session) => { list.append(makeRow(session)); });
      }
    } else {
      sessions.forEach((session) => { list.append(makeRow(session)); });
    }
    list.scrollTop = previousScroll;
    if (focusedKey !== null) {
      [...list.querySelectorAll('.session-row')].find((row) => row.dataset.key === focusedKey)?.focus({ preventScroll: true });
    }
  }

  function metaLine(label, content) {
    const line = node('div', 'meta-line');
    line.append(node('dt', '', label), node('dd', '', content));
    return line;
  }

  function renderDetail() {
    const hadFocusButton = document.activeElement?.classList?.contains('focus-button');
    const messageScroll = detail.querySelector('.message-list')?.scrollTop || 0;
    detail.replaceChildren();
    const session = selectedSession();
    $('detail-close').hidden = !session;
    if (!session) {
      const empty = node('div', 'detail-empty');
      empty.append( node('h3', '', 'セッションを選択'), node('p', '', '一覧から選択して、会話や端末の表示を確認できます。'));
      detail.append(empty);
      return;
    }
    detail.append(node('h3', 'detail-title', sessionName(session)));
    const meta = node('div', 'detail-meta');
    const dot = node('i', `status-dot ${knownStatus(session.status)}`);
    dot.setAttribute('aria-hidden', 'true');
    meta.append(dot, node('span', '', STATUS[knownStatus(session.status)]), node('span', '', '·'), node('span', '', value(session.agent, 'エージェント不明')));
    detail.append(meta);
    if (knownStatus(session.status) === 'not_active') {
      detail.append(node('p', 'status-explanation', 'Herdrにペインがありません。終了したかどうかは確認できていません。'));
    }
    if (!visibleSessions().some((item) => item.key === session.key)) {
      detail.append(node('p', 'message-warning', 'このセッションは現在の表示対象には含まれていません。'));
    }
    const context = node('dl', 'detail-context');
    context.append(metaLine('プロジェクト', workspaceName(session)), metaLine('作業場所', value(session.cwd, '不明')),
      metaLine('更新', fullTime(session.updated_at)));
    if (value(session.source)) context.append(metaLine('取得元', session.source));
    if (value(session.status_source)) context.append(metaLine('状態の根拠', session.status_source));
    detail.append(context);
    const button = node('button', 'focus-button', state.focusing ? '端末を開いています…' : '↗  端末で開く');
    button.type = 'button';
    button.setAttribute('aria-label', state.focusing ? '端末を開いています' : '端末で開く');
    button.disabled = !value(session.pane_id) || state.focusing;
    button.addEventListener('click', () => focusPane(session));
    detail.append(button);
    detail.append(node('p', 'focus-help', value(session.pane_id)
      ? 'このセッションの端末ペインに移動します。' : '端末ペインが取得できないため、開けません。'));
    if (state.focusError) {
      const error = node('p', 'action-error', state.focusError);
      error.setAttribute('role', 'alert');
      detail.append(error);
    }

    const conversation = node('section', 'conversation');
    const heading = node('div', 'conversation-head');
    heading.append(node('h3', '', state.messagesPreview ? '端末の最近の表示' : state.messages ? '最近の会話' : '記録'));
    conversation.append(heading);
    if (state.messagesPreview) {
      conversation.append(node('p', 'preview-explanation', state.previewHasSessionId
        ? 'セッションIDは報告済みです。保存された会話履歴が見つからない、またはまだ記録されていないため、端末の最近の表示を代わりに表示しています。'
        : 'セッションIDがまだ報告されていないため、ここでは会話履歴ではなく端末の表示を示しています。'));
    }
    if (state.messagesLoading && !state.messages) conversation.append(node('p', 'message-state', '記録を読み込んでいます…'));
    if (state.messagesError) conversation.append(node('p', 'message-warning', `${state.messagesError}${state.messages ? ' · 前回の内容を表示中' : ''}`));
    if (state.messages) {
      if (!state.messages.length) conversation.append(node('p', 'message-state', state.messagesPreview ? '端末の表示はまだありません。' : '現在、表示できる会話はありません。'));
      else {
        const messages = node('div', `message-list${state.messagesPreview ? ' preview' : ''}`);
        state.messages.forEach((message) => {
          const item = node('article', 'message');
          const head = node('div', 'message-head');
          const role = value(message.role, '不明');
          head.append(node('span', `message-role${role === 'user' ? ' user' : ''}`,
            role === 'user' ? 'あなた' : role === 'assistant' ? 'アシスタント' : role === 'terminal' ? '端末' : role));
          if (message.timestamp !== '' && message.timestamp != null) head.append(node('time', '', timeLabel(message.timestamp)));
          item.append(head, node('p', 'message-text', typeof message.text === 'string' && message.text.length
            ? message.text : state.messagesPreview ? '（表示なし）' : '（本文なし）'));
          messages.append(item);
        });
        conversation.append(messages);
      }
      if (state.messagesTruncated) conversation.append(node('p', 'message-warning', state.messagesPreview
        ? '端末の表示の一部のみを表示しています。' : '会話の一部のみを表示しています。'));
    }
    detail.append(conversation);
    if (detail.querySelector('.message-list')) detail.querySelector('.message-list').scrollTop = messageScroll;
    if (hadFocusButton && !button.disabled) button.focus({ preventScroll: true });
  }

  function render() { setSync(); renderSummary(); renderList(); renderDetail(); }

  async function loadSessions() {
    if (state.loading) return;
    state.loading = true;
    setSync();
    try {
      const data = await getJSON('/api/sessions');
      if (!Array.isArray(data.sessions)) throw new Error('一覧の形式が正しくありません。');
      state.sessions = data.sessions.filter((item) => item && typeof item.key === 'string');
      state.updatedAt = Date.now();
      state.stale = false;
      state.warning = value(data.warning);
      state.listError = '';
      if (state.selectedKey && !selectedSession()) {
        state.selectedKey = null;
        state.messageRequest++;
        state.messages = null;
        state.messagesPreview = false;
        state.previewHasSessionId = false;
        state.messagesLoading = false;
        state.messagesError = '';
      }
      if (state.selectedKey && !state.messagesLoading && Date.now() - state.lastMessageFetch >= 15000) loadMessages(state.selectedKey, false);
    } catch (error) {
      state.listError = error.message || '接続を確認してください。';
      state.stale = true;
    } finally {
      state.loading = false;
      render();
    }
  }

  async function loadMessages(key, clear) {
    const request = ++state.messageRequest;
    state.messagesLoading = true;
    state.messagesError = '';
    if (clear) {
      state.messages = null;
      state.messagesPreview = false;
      state.previewHasSessionId = false;
      state.messagesTruncated = false;
    }
    renderDetail();
    try {
      const data = await getJSON(`/api/sessions/${encodeURIComponent(key)}/messages`);
      if (!Array.isArray(data.messages)) throw new Error('会話の形式が正しくありません。');
      if (request !== state.messageRequest || state.selectedKey !== key) return;
      state.messages = data.messages.filter((item) => item && typeof item === 'object');
      state.messagesPreview = data.preview === true;
      state.previewHasSessionId = state.messagesPreview && Boolean(value(selectedSession()?.session_id));
      state.messagesTruncated = data.truncated === true;
      state.lastMessageFetch = Date.now();
    } catch (error) {
      if (request !== state.messageRequest || state.selectedKey !== key) return;
      state.messagesError = state.messages ? '記録を更新できませんでした。' : '記録を取得できませんでした。';
      state.lastMessageFetch = Date.now();
    } finally {
      if (request === state.messageRequest && state.selectedKey === key) {
        state.messagesLoading = false;
        renderDetail();
      }
    }
  }

  function selectSession(key) {
    if (state.selectedKey === key) return;
    state.selectedKey = key;
    state.focusError = '';
    state.focusing = false;
    state.lastMessageFetch = 0;
    renderList();
    loadMessages(key, true);
    if (window.matchMedia('(max-width: 760px)').matches) $('detail-pane').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  async function focusPane(session) {
    if (state.focusing || !value(session.pane_id)) return;
    state.focusing = true;
    state.focusError = '';
    renderDetail();
    try {
      const data = await getJSON('/api/focus', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Session-Dashboard': '1' }, body: JSON.stringify({ pane_id: session.pane_id }) });
      if (data.ok !== true) throw new Error('端末を開けませんでした。');
    } catch (error) {
      if (state.selectedKey === session.key) state.focusError = error.message || '端末を開けませんでした。';
    } finally {
      state.focusing = false;
      renderDetail();
      if (state.selectedKey === session.key) detail.querySelector('.focus-button')?.focus({ preventScroll: true });
    }
  }

  $('refresh-button').addEventListener('click', loadSessions);
  $('search-input').addEventListener('input', (event) => { state.query = event.target.value.trim(); renderList(); });
  for (const [id, scope] of [['scope-live', 'live'], ['scope-history', 'history']]) {
    $(id).addEventListener('click', () => {
      if (state.scope === scope) return;
      state.scope = scope;
      state.filter = 'all';
      state.query = '';
      $('search-input').value = '';
      state.selectedKey = null;
      state.messageRequest++;
      state.messages = null;
      state.messagesPreview = false;
      state.previewHasSessionId = false;
      state.messagesLoading = false;
      state.messagesError = '';
      state.focusError = '';
      list.scrollTop = 0;
      $('list-heading').replaceChildren(document.createTextNode(`${scope === 'live' ? '稼働中のペイン' : 'セッション履歴'} `), $('visible-count'));
      $('scope-live').setAttribute('aria-pressed', String(scope === 'live'));
      $('scope-history').setAttribute('aria-pressed', String(scope === 'history'));
      $('status-filters').hidden = scope === 'history';
      $('history-views').hidden = scope === 'live';
      $('status-filters').querySelectorAll('button').forEach((button) => {
        button.setAttribute('aria-pressed', String(button.dataset.status === 'all'));
      });
      render();
    });
  }
  $('status-filters').addEventListener('click', (event) => {
    const button = event.target.closest('button[data-status]');
    if (!button) return;
    state.filter = button.dataset.status;
    $('status-filters').querySelectorAll('button').forEach((item) => { item.setAttribute('aria-pressed', String(item === button)); });
    renderList();
    renderDetail();
  });
  for (const [id, view] of [['view-grouped', 'grouped'], ['view-compact', 'compact']]) {
    $(id).addEventListener('click', () => {
      state.view = view;
      $('view-grouped').setAttribute('aria-pressed', String(view === 'grouped'));
      $('view-compact').setAttribute('aria-pressed', String(view === 'compact'));
      renderList();
    });
  }
  list.addEventListener('keydown', (event) => {
    if (!['ArrowDown', 'ArrowUp', 'Home', 'End'].includes(event.key)) return;
    const rows = [...list.querySelectorAll('.session-row')];
    if (!rows.length) return;
    event.preventDefault();
    const index = rows.indexOf(document.activeElement);
    const next = event.key === 'Home' ? 0 : event.key === 'End' ? rows.length - 1
      : event.key === 'ArrowDown' ? Math.min(index + 1, rows.length - 1) : Math.max(index - 1, 0);
    rows[next].focus();
  });
  $('detail-close').addEventListener('click', () => {
    const oldKey = state.selectedKey;
    state.selectedKey = null;
    state.messageRequest++;
    state.messages = null;
    state.messagesPreview = false;
    state.previewHasSessionId = false;
    state.messagesLoading = false;
    state.messagesError = '';
    state.focusError = '';
    render();
    const row = [...list.querySelectorAll('.session-row')].find((item) => item.dataset.key === oldKey);
    row?.focus();
    if (window.matchMedia('(max-width: 760px)').matches) row?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  });

  async function poll() {
    await loadSessions();
    setTimeout(poll, POLL_MS);
  }
  poll();
})();
