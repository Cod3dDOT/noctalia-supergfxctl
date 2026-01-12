/*
 * Icons helper singleton
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

const compare = (v1, v2) => v1.localeCompare(v2, undefined, { numeric: true });

function greater(a, b) {
	return compare(a, b) > 0;
}

function inRange(version, min, max, inclusive = true) {
    const isAboveMin = inclusive ? compare(version, min) >= 0 : compare(version, min) > 0;
    const isBelowMax = inclusive ? compare(version, max) <= 0 : compare(version, max) < 0;

    return isAboveMin && isBelowMax;
}
