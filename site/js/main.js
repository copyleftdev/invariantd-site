// invariantd.com — film player + chain reveal + form enhancement. No dependencies.

// Hero film: poster + one play control. The video is not fetched until asked
// (preload="none"), so the landing stays light; play is user-initiated, so it
// carries sound. Native controls appear once it starts.
(() => {
  document.querySelectorAll('[data-film]').forEach((frame) => {
    const video = frame.querySelector('.film-video');
    const play = frame.querySelector('[data-play]');
    if (!video || !play) return;

    const start = () => {
      frame.classList.add('is-playing');
      video.setAttribute('controls', '');
      const p = video.play();
      if (p && typeof p.catch === 'function') p.catch(() => {});
      video.focus({ preventScroll: true });
    };
    play.addEventListener('click', start);
    video.addEventListener('play', () => frame.classList.add('is-playing'));
    video.addEventListener('ended', () => {
      frame.classList.remove('is-playing');
      video.removeAttribute('controls');
      video.load(); // restore the poster
    });
  });
})();

// Violation readout: reveal lines in sequence when the band scrolls into view.
(() => {
  const screen = document.querySelector('[data-chain]');
  if (!screen) return;
  screen.querySelectorAll('.ro-line').forEach((line, i) => {
    line.style.setProperty('--i', i);
  });
  screen.classList.add('anim-ready');
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          screen.classList.add('is-live');
          observer.disconnect();
        }
      }
    },
    { threshold: 0.4 }
  );
  observer.observe(screen);
})();

// Contact form: submit in place; native POST remains the no-JS fallback.
(() => {
  const form = document.querySelector('[data-contact]');
  if (!form) return;
  const status = form.querySelector('.form-status');
  const button = form.querySelector('button[type="submit"]');

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    button.disabled = true;
    status.className = 'form-status';
    status.textContent = 'Sending…';
    try {
      const response = await fetch(form.action, {
        method: 'POST',
        headers: { Accept: 'application/json' },
        body: new FormData(form),
      });
      if (!response.ok) throw new Error(String(response.status));
      form.reset();
      status.classList.add('is-ok');
      status.textContent = 'Received. We read every message.';
    } catch {
      status.classList.add('is-err');
      status.textContent = 'Something failed in transit — please try again in a minute.';
      button.disabled = false;
    }
  });
})();
