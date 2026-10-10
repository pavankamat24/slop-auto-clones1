const signup = document.querySelector('#signup');
document.querySelectorAll('[data-open]').forEach(button => button.addEventListener('click', () => signup.showModal()));
document.querySelectorAll('dialog').forEach(dialog => {
  dialog.querySelector('.close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => { if (event.target === dialog) { const rect = dialog.getBoundingClientRect(); if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close(); } });
});
document.querySelector('#signup-form').addEventListener('submit', event => {
  event.preventDefault();
  const email = document.querySelector('#email').value.trim();
  try { localStorage.setItem('panto-early-access', email); document.querySelector('#signup-result').textContent = 'Your interest is saved on this device. Thanks for exploring Panto!'; }
  catch { document.querySelector('#signup-result').textContent = 'Your browser could not save your interest. Please enable local storage and try again.'; }
});
const reviews = [
  { title: 'feat: add user authentication flow', content: '<h3>2 suggestions · Authentication</h3><p>Consider rotating the session token after a successful login to reduce the risk of session fixation.</p><code>await session.regenerate();\nreturn createSession(user.id);</code><p>Add a rate limit to failed sign-in attempts to help prevent brute-force attacks.</p>' },
  { title: 'fix: handle edge case in payment webhook', content: '<h3>1 issue found · Duplicate events</h3><p>The payment provider can send the same event more than once. Check the event ID before processing to avoid duplicate charges.</p><code>if (await events.exists(event.id)) {\n  return response.status(200).end();\n}</code><p>Use an atomic database operation to store the event and apply its changes together.</p>' },
  { title: 'refactor: simplify database queries', content: '<h3>✓ Looks good</h3><p>The sample review found no actionable issues. The refactor reduces repeated queries while preserving the existing behavior.</p><code>// Review complete\n// No changes suggested</code>' }
];
document.querySelectorAll('[data-review]').forEach(button => button.addEventListener('click', () => {
  const review = reviews[Number(button.dataset.review)];
  document.querySelector('#review-title').textContent = review.title;
  document.querySelector('#review-content').innerHTML = review.content;
  document.querySelector('#review-dialog').showModal();
}));
const views = {
  overview: ['Overview', 'Good morning, Jamie ☀', "Here's how Panto is keeping your code in good shape."],
  reviews: ['Pull requests', 'Your latest pull requests', 'Select a sample review to explore the findings.'],
  insights: ['Insights', 'A healthier codebase, every week', '128 reviews. 43 issues caught. More room for your next big idea.']
};
function setView(view) {
  document.querySelectorAll('[data-view]').forEach(button => button.classList.toggle('selected', button.dataset.view === view));
  ['view-title', 'greeting-title', 'greeting-copy'].forEach((id, i) => document.getElementById(id).textContent = views[view][i]);
  document.querySelector('.stats').hidden = view === 'reviews';
}
document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click', () => setView(button.dataset.view)));
document.querySelector('#view-all').addEventListener('click', () => { setView('reviews'); document.querySelector('#greeting-copy').textContent = 'All 3 sample reviews are shown below. Select one to see the details.'; });
document.querySelectorAll('[data-repo]').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('[data-repo]').forEach(item => item.classList.toggle('active', item === button));
  document.querySelectorAll('.repo-name').forEach(item => item.textContent = button.dataset.repo);
  document.querySelector('#greeting-copy').textContent = `Sample review activity for ${button.dataset.repo}.`;
}));
let month = false;
document.querySelector('#period').addEventListener('click', event => {
  month = !month; event.currentTarget.textContent = month ? 'Last 30 days ⌄' : 'Last 7 days ⌄';
  document.querySelector('#pr-stat').textContent = month ? '512' : '128';
  document.querySelector('#issue-stat').textContent = month ? '156' : '43';
  document.querySelector('#hour-stat').innerHTML = `${month ? '124' : '32'}<span>hrs</span>`;
  document.querySelectorAll('.stats em').forEach(item => item.textContent = month ? 'vs. last month' : 'vs. last week');
});
