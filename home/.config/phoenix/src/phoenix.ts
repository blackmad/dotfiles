import {frameRatio, moveToFrame} from './calc';
import {hyper, hyperShift} from './config';
import {cycleBackward, cycleForward} from './cycle';
import {onKey} from './key';
import log from './logger';
import coffeeTimer, {TimerStopper} from './misc/coffee';
import * as terminal from './misc/terminal';
import {showCenterOn, titleModal} from './modal';
import {Scanner} from './scan';
import {screenAt} from './screen';
import {sleep} from './util';
import {setFrame, setFrameWithoutWin, toggleMaximized} from './window';

const scanner = new Scanner();
let coffee: TimerStopper | null;

Phoenix.set({
	daemon: true,
	openAtLogin: true,
});

Event.on('screensDidChange', () => {
	log('Screens changed');
});

// MouseAction WIP.
interface MouseAction {
	type: 'move' | 'resize';
	win: Window;
	wf: Rectangle;
	sf: Rectangle;
	mp: MousePoint;
}

let enableMouseAction = false;
let mouseAction: MouseAction | undefined;

const enableMouseActionHandler: (handler: Key, repeated: boolean) => void = (
	_,
	repeat,
) => {
	if (repeat) {
		return;
	}
	enableMouseAction = !enableMouseAction;
};

function hasMouseModifiers(
	{modifiers}: {modifiers: Phoenix.ModifierKey[]},
	compare: Phoenix.ModifierKey[],
): boolean {
	return (
		Math.ceil(modifiers.length / 2) == compare.length &&
		compare.map((key) => modifiers.includes(key)).every((x) => x)
	);
}

const mouseActionHandler: (target: MousePoint, handler: Event) => void = (
	target,
) => {
	let type: 'move' | 'resize';
	if (enableMouseAction && hasMouseModifiers(target, hyper)) {
		type = 'move';
	} else if (enableMouseAction && hasMouseModifiers(target, hyperShift)) {
		type = 'resize';
	} else {
		enableMouseAction = false;
		mouseAction = undefined;
		return;
	}
	if (!mouseAction) {
		const win = Window.at(target);
		if (!win) {
			return;
		}
		mouseAction = {
			type,
			win,
			wf: win.frame(),
			sf: win.screen().flippedVisibleFrame(),
			mp: {...target},
		};
	} else if (mouseAction.type !== type) {
		// Reset origin on type change because
		// resizing the old frame is weird.
		mouseAction = {
			type,
			win: mouseAction.win,
			wf: mouseAction.win.frame(),
			sf: mouseAction.sf,
			mp: {...target},
		};
	}
	const x = mouseAction.mp.x - target.x;
	const y = mouseAction.mp.y - target.y;
	if (x === 0 && y === 0) {
		return;
	}
	log(mouseAction.win.screen().flippedVisibleFrame());
	const nf = {...mouseAction.wf};
	if (type === 'move') {
		if (target.y === 0) {
			// TODO: Make it non-instant, revert if dragged back.
			mouseAction.win.maximize();
			return;
		}
		nf.x -= x;
		nf.y -= y;
		// Handle sticky edges.
		const stickyThreshold = 15;
		if (Math.abs(mouseAction.sf.x - nf.x) <= stickyThreshold) {
			nf.x = mouseAction.sf.x;
		}
		const rx = mouseAction.sf.width - nf.width;
		if (Math.abs(rx - nf.x) <= stickyThreshold) {
			nf.x = rx;
		}
		if (Math.abs(mouseAction.sf.y - nf.y) <= stickyThreshold) {
			nf.y = mouseAction.sf.y;
		}
		const by = mouseAction.sf.y + mouseAction.sf.height - nf.height;
		if (Math.abs(by - nf.y) <= stickyThreshold) {
			nf.y = by;
		}

		mouseAction.win.setTopLeft(nf);
	} else {
		// Keep window centered at origin.
		nf.x += x;
		if (nf.x < mouseAction.sf.x) {
			nf.x = mouseAction.sf.x;
		}
		nf.y += y;
		if (nf.y < mouseAction.sf.y) {
			nf.y = mouseAction.sf.y;
		}
		// TODO(mafredri): Keep within screen frame.
		nf.width -= x * 2;
		nf.height -= y * 2;
		mouseAction.win.setFrame(nf);
	}
};

Event.on('mouseDidMove', mouseActionHandler);
onKey('a', hyper, enableMouseActionHandler);
onKey('a', hyperShift, enableMouseActionHandler);

onKey('tab', hyper, async () => {
	const win = Window.focused();
	if (!win) {
		return;
	}

	const fullscreen = win.isFullScreen();
	if (fullscreen) {
		win.setFullScreen(false);
		// If we don't wait until the animation is finished,
		// bad things will happen (at least with VS Code).
		//
		// 750ms seems to work, but just to be safe.
		await sleep(900);
	}

	const oldScreen = win.screen();
	const newScreen = oldScreen.next();

	if (oldScreen.isEqual(newScreen)) {
		return;
	}

	const ratio = frameRatio(
		oldScreen.flippedVisibleFrame(),
		newScreen.flippedVisibleFrame(),
	);
	setFrame(win, ratio(win.frame()));

	if (fullscreen) {
		await sleep(900);
		win.setFullScreen(true);
	}

	// Force space switch, in case another one is focused on the screen.
	win.focus();
});

function makeFrame(
	widthSizePercentage: number,
	heightSizePercentage: number,
	widthPlacementPercentage: number,
	heightPlacementPercentage: number,
) {
	const win = Window.focused();
	if (!win) {
		return undefined;
	}

	const {width, height, x, y} = win.screen().flippedVisibleFrame();
	const frame = {
		width: Math.floor(width * widthSizePercentage),
		height: Math.floor(height * heightSizePercentage),
		x: x + Math.floor(width * widthPlacementPercentage),
		y: y + Math.floor(height * heightPlacementPercentage),
	};

	return frame;
}

function makeLeftFrames() {
	const win = Window.focused();
	if (!win) {
		return [];
	}

	const {width, height, x, y} = win.screen().flippedVisibleFrame();
	const frame2 = {width: Math.floor(width / 2), height, x, y};
	const frame3 = {width: Math.floor(width / 3), height, x, y};
	const frame4 = {width: Math.floor(width / 4), height, x, y};

	const possibleFrames = [frame2, frame3];
	if (width > 1600) {
		possibleFrames.push(frame4);
	}
	return possibleFrames;
}

onKey(['left', 'j'], hyper, () => {
	const win = Window.focused();
	if (!win) {
		return;
	}

	const possibleRightFRames = makeRightFrames();
	const allWindows = Window.recent().slice(0, 2);
	const foundRightFrame = possibleRightFRames.find((frame) =>
		allWindows.find((win) => objEq(frame, win.frame())),
	);

	log({foundRightFrame});

	const possibleFrames = makeLeftFrames();

	if (foundRightFrame) {
		possibleFrames.unshift({
			...foundRightFrame,
			width:
				win.screen().flippedVisibleFrame().width -
				foundRightFrame.width,
			x: 0,
		});
	}

	setFrame(win, ...possibleFrames);
});

function makeRightFrames() {
	const win = Window.focused();
	if (!win) {
		return [];
	}
	const {width, height, x, y} = win.screen().flippedVisibleFrame();
	const frame2 = {
		width: Math.floor(width / 2),
		height,
		x: x + Math.ceil(width / 2),
		y,
	};
	const frame3 = {
		width: Math.floor(width / 3),
		height,
		x: x + Math.ceil((width / 3) * 2),
		y,
	};
	const frame4 = {
		width: Math.floor(width / 4),
		height,
		x: x + Math.ceil((width / 4) * 3),
		y,
	};

	const possibleFrames = [frame2, frame3];
	if (width > 1600) {
		possibleFrames.push(frame4);
	}
	return possibleFrames;
}

onKey(['right', 'l'], hyper, () => {
	const win = Window.focused();
	if (!win) {
		return;
	}

	const possibleLeftFrames = makeLeftFrames();
	const allWindows = Window.recent().slice(0, 2);
	const foundLeftFrame = possibleLeftFrames.find((frame) =>
		allWindows.find((win) => objEq(frame, win.frame())),
	);

	log({foundLeftFrame});
	const possibleFrames = makeRightFrames();

	if (foundLeftFrame) {
		possibleFrames.unshift({
			...foundLeftFrame,
			width:
				win.screen().flippedVisibleFrame().width - foundLeftFrame.width,
			x: foundLeftFrame.width,
		});
	}

	setFrame(win, ...possibleFrames);
});

onKey(['up', 'i'], hyper, () => {
	setFrameWithoutWin(makeUpFrame(), makeDownFrame());
});

onKey(['q'], hyper, () => {
	setFrameWithoutWin(
		makeFrame(1 / 2, 1 / 2, 0, 0),
		makeFrame(1 / 3, 1 / 2, 0, 0),
	);
});

onKey(['w'], hyper, () => {
	setFrameWithoutWin(
		makeFrame(1 / 2, 1 / 2, 1 / 2, 0),
		makeFrame(1 / 3, 1 / 2, 2 / 3, 0),
	);
});

onKey(['a'], hyper, () => {
	setFrameWithoutWin(
		makeFrame(1 / 2, 1 / 2, 0, 1 / 2),
		makeFrame(1 / 3, 1 / 2, 0, 1 / 2),
	);
});

onKey(['s'], hyper, () => {
	setFrameWithoutWin(
		makeFrame(1 / 2, 1 / 2, 1 / 2, 1 / 2),
		makeFrame(1 / 3, 1 / 2, 2 / 3, 1 / 2),
	);
});

function makeDownFrame() {
	const win = Window.focused();
	if (!win) {
		return;
	}

	let {height, width, y, x} = win.screen().flippedVisibleFrame();
	height /= 2;
	[height, y] = [Math.ceil(height), y + Math.floor(height)];
	return {height, width, x: 0, y};
}

function makeUpFrame() {
	const win = Window.focused();
	if (!win) {
		return;
	}

	let {height, width, y} = win.screen().flippedVisibleFrame();
	return {height: Math.ceil(height / 2), width, x: 0, y};
}

onKey(['down', 'k'], hyper, () => {
	setFrameWithoutWin(makeDownFrame(), makeUpFrame());
});

onKey('return', hyper, () => {
	const win = Window.focused();
	if (win) {
		toggleMaximized(win);
	}
});

onKey('return', hyperShift, () => {
	const win = Window.focused();
	if (!win) {
		return;
	}
	win.setFullScreen(!win.isFullScreen());
});

onKey('§', [], (_, repeated) => {
	if (repeated) {
		return;
	}
	terminal.toggle();
});
onKey('§', ['cmd'], (_, repeated) => {
	if (repeated) {
		return;
	}
	terminal.cycleWindows();
});

onKey('p', hyper, () => {
	const win = Window.focused();
	if (!win) {
		return;
	}
	const app = win.app().name();
	const bundleId = win.app().bundleIdentifier();
	const pid = win.app().processIdentifier();
	const title = win.title();
	const frame = win.frame();
	const msg = [
		`Application: ${app}`,
		`Title: ${title}`,
		`Frame: X=${frame.x}, Y=${frame.y}`,
		`Size: H=${frame.height}, W=${frame.width}`,
		`Bundle ID: ${bundleId}`,
		`PID: ${pid}`,
	].join('\n');

	log('Window information:\n' + msg);

	const modal = Modal.build({
		duration: 10,
		icon: win.app().icon(),
		text: msg,
		weight: 16,
	});
	showCenterOn(modal, Screen.main());
});

onKey('.', hyper, () => {
	const win = Window.focused();
	if (win) {
		log(
			win
				.screen()
				.windows({visible: true})
				.map((w) => w.title()),
		);
		log(
			win
				.screen()
				.windows()
				.map((w) => w.title()),
		);
	}
});

onKey('delete', hyper, () => {
	const win = Window.focused();
	if (win) {
		const visible = win.screen().windows({visible: true});
		log(visible.map((w) => w.title()));
		// log(win.screen().windows({visible: true}).map(w => w.title()));
		// log(win.others({visible: true}).map(w => w.title()));
		win.minimize();
		if (visible.length) {
			const next = visible[visible.length > 1 ? 1 : 0];
			log('focusing: ' + next.title());
			next.focus();
		}
		// win.focusClosestNeighbor('east');
		// const others = win.others({visible: true});
		// if (others.length) {
		// 	log(others.map(w => w.title()));
		// 	others[0].focus();
		// }
	}
});

onKey('m', hyper, () => {
	const s = screenAt(Mouse.location());
	log(s.identifier(), Mouse.location());
});

onKey('c', hyper, () => {
	if (coffee) {
		coffee.stop();
		coffee = null;
		return;
	}
	coffee = coffeeTimer({screen: Screen.main(), timeout: 8});
});

onKey('escape', ['cmd'], () => cycleForward(Window.focused()));
onKey('escape', ['cmd', 'shift'], () => cycleBackward(Window.focused()));

// Experimental: Search for windows and cycle between results.
// onKey('space', hyper, () => {
// 	const m = new Modal();
// 	const msg = 'Search: ';
// 	m.text = msg;
// 	showCenterOn(m, Screen.main());
// 	const originalWindow = Window.focused();
// 	const winCache = Window.all({visible: true});
// 	let matches = [...winCache];

// 	// Prevent modal from hopping from screen to screen.
// 	const mainScreen = Screen.main();

// 	// Since we focus the first window, start in reverse mode.
// 	let prevReverse = true;

// 	function nextWindow(reverse: boolean): Window | undefined {
// 		if (prevReverse !== reverse) {
// 			prevReverse = reverse;
// 			nextWindow(reverse); // Rotate.
// 		}

// 		const w = reverse ? matches.pop() : matches.shift();
// 		if (!w) {
// 			return;
// 		}
// 		reverse ? matches.unshift(w) : matches.push(w);
// 		return w;
// 	}

// 	const tabFn = (reverse: boolean) => () => {
// 		if (!matches.length) {
// 			return;
// 		}

// 		const w = nextWindow(reverse);
// 		if (!w) {
// 			return;
// 		}

// 		w.focus();
// 		m.icon = w.app().icon();
// 		showCenterOn(m, mainScreen);
// 	};

// 	const tab = new Key('tab', [], tabFn(false));
// 	const shiftTab = new Key('tab', ['shift'], tabFn(true));

// 	scanner.scanln(
// 		(s) => {
// 			m.close();
// 			tab.disable();
// 			shiftTab.disable();
// 			if (s === '' && originalWindow) {
// 				// No window selected, restore original.
// 				originalWindow.focus();

// 				// Window management on macOS with multiple monitors is pretty
// 				// bad, the right window might not be focused when an app is not
// 				// focused and has multiple windows on multiple monitors.
// 				setTimeout(() => originalWindow.focus(), 200);
// 			}
// 		},
// 		(s) => {
// 			tab.enable();
// 			shiftTab.enable();

// 			prevReverse = true; // Reset.

// 			matches = winCache.filter((w) => appName(w) || title(w));
// 			m.text = msg + s + (s ? results(matches.length) : '');

// 			if (s && matches.length) {
// 				matches[0].focus();
// 				m.icon = matches[0].app().icon();
// 			} else {
// 				if (originalWindow) {
// 					originalWindow.focus();
// 				}
// 				m.icon = undefined;
// 			}

// 			showCenterOn(m, mainScreen);

// 			function appName(w: Window) {
// 				return w.app().name().toLowerCase().match(s.toLowerCase());
// 			}

// 			function title(w: Window) {
// 				return w.title().toLowerCase().match(s.toLowerCase());
// 			}
// 		},
// 	);

// 	function results(n: number) {
// 		return `\n${n} results`;
// 	}
// });

// Always hide apps, even if they're the last one on the desktop.
onKey('h', ['cmd'], (_: Key, repeated: boolean) => {
	// Hide all windows when Cmd+H is held.
	if (repeated) {
		const apps = Window.all({visible: true}).map((w) => w.app());
		new Set(apps).forEach((a) => a.hide());
		return;
	}

	const win = Window.focused();
	if (win) {
		win.app().hide();
	}
});

function objEq(a: {[key: string]: any}, b: {[key: string]: any}) {
	const akeys = Object.keys(a);
	if (akeys.length !== Object.keys(b).length) {
		return false;
	}
	return akeys.every((k) => a[k] === b[k]);
}

const phoenixApp = App.get('Phoenix') || App.get('Phoenix (Debug)');
titleModal('Phoenix (re)loaded!', 2, phoenixApp && phoenixApp.icon());

// Magic!

Event.on('windowDidOpen', magiciTermOpen); //FIXME: Doesn't seem to be working

/* HANDLER */

function magiciTermOpen(window: Window) {
	if (!window.isNormal() || !window.isMain()) return;

	const name = window.app().name();

	if (!/iTerm/.test(name) || false) return;

	log('it is iterm');

	// setFrame('bottom-left', window);
}
