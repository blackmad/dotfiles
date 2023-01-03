import {frameRatio} from './calc';
import log from './logger';

interface FrameCache {
	screen: Rectangle;
	window: Rectangle;
	maximized?: {
		screen: Rectangle;
		window: Rectangle;
	};
}

const frameCache: Map<number, FrameCache> = new Map();

Event.on('windowDidClose', (win: Window) => {
	// Cleanup references to unmaximized window frames.
	frameCache.delete(win.hash());
});

function unmaximizedFrame(win: Window): Rectangle {
	let c = frameCache.get(win.hash());
	if (!c) {
		c = {
			screen: win.screen().flippedVisibleFrame(),
			window: win.frame(),
		};
	}
	const ratio = frameRatio(c.screen, win.screen().flippedVisibleFrame());
	return ratio(c.window);
}

function objEqual(a: {[key: string]: any}, b: {[key: string]: any}): boolean {
	if (typeof a !== 'object') {
		return a === b;
	}
	if (Object.keys(a).length !== Object.keys(b).length) {
		return false;
	}
	for (const key of Object.keys(a)) {
		if (typeof a[key] === 'object') {
			if (!objEqual(a[key], b[key])) {
				return false;
			}
		}
		if (a[key] !== b[key]) {
			return false;
		}
	}
	return true;
}

function isMaximized(win: Window): boolean {
	const cache = frameCache.get(win.hash());
	if (!cache || !cache.maximized) {
		return false;
	}

	log(win.frame(), cache.maximized.window);

	return (
		objEqual(win.screen().flippedVisibleFrame(), cache.maximized.screen) &&
		objEqual(win.frame(), cache.maximized.window)
	);
}

export function toggleMaximized(win: Window): boolean {
	if (isMaximized(win)) {
		return setFrame(win, unmaximizedFrame(win));
	}
	return maximize(win);
}

export function setFrameWithoutWin(
	...frames: Array<Rectangle | undefined>
): boolean {
	const win = Window.focused();
	if (!win) {
		return false;
	}
	return setFrame(win, ...frames);
}

export function setFrame(
	win: Window,
	...frames: Array<Rectangle | undefined>
): boolean {
	for (const frame of frames) {
		if (!frame) {
			continue;
		}
		log('comparing', win.frame(), frame);

		if (objEqual(win.frame(), frame)) {
			continue;
		}
		return setFrameHelper(win, frame);
	}
	return false;
}

function setFrameHelper(win: Window, frame: Rectangle): boolean {
	const ok = win.setFrame(frame);
	if (ok) {
		frameCache.delete(win.hash());
	}
	return ok;
}

export function maximize(win: Window): boolean {
	const previous = {
		screen: win.screen().flippedVisibleFrame(),
		window: win.frame(),
	};
	const ok = win.maximize();
	const id = win.hash();
	frameCache.set(id, {
		...previous,
		maximized: {
			screen: win.screen().flippedVisibleFrame(),
			window: win.frame(),
		},
	});
	return ok;
}
