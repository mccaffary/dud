module dud.semver2.versionunion;

import std.algorithm.sorting : sort;
import std.array : empty, front, popFront;
import std.format : format, formattedWrite;
import dud.semver2.versionrange;
import dud.semver2.semver;

@safe pure:

struct VersionUnion {
@safe pure:
	VersionRange[] ranges;

	this(const(VersionRange)[] rng) {
		foreach(it; rng) {
			this.insert(it);
		}
	}

	void insert(const(VersionRange) nvu) {
		this.ranges = merge(this.ranges, nvu);
	}

	VersionUnion dup() const {
		import std.array : array;
		import std.algorithm.iteration : map;
		VersionUnion ret;
		ret.ranges = this.ranges.map!(it => it.dup).array;
		return ret;
	}
}

VersionRange merge(const(VersionRange) a, const(VersionRange) b) {
	const SemVer low = a.low < b.low ? a.low : b.low;
	const Inclusive lowInc = low == a.low ? a.inclusiveLow : b.inclusiveLow;

	const SemVer high = a.high > b.high ? a.high : b.high;
	const Inclusive highInc = high == a.high ? a.inclusiveHigh : b.inclusiveHigh;

	const bool notIntersect =
		(a.high == b.low
			&& (a.inclusiveHigh == false || b.inclusiveLow == false))
		|| (a.low == b.high
			&& (a.inclusiveLow == false || b.inclusiveHigh == false))
		|| (a.high < b.low)
		|| (a.low > b.high);

	return notIntersect
		? VersionRange.init
		: VersionRange(low, lowInc, high, highInc);
}

package VersionRange[] merge(const(VersionRange)[] old,
		const(VersionRange) nvu)
{
	VersionRange[] ret;
	if(old.empty) {
		return [ nvu.dup() ];
	}

	ret ~= nvu.dup;

	foreach(it; old) {
		VersionRange top = ret.front();
		ret.popFront();

		VersionRange m = merge(top, it);
		if(m == VersionRange.init) {
			ret ~= top;
			ret ~= it.dup();
		} else {
			ret ~= m;
		}
	}

	ret.sort();

	return ret;
}
