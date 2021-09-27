;----------------------------------------------------------------------
/*
https://gist.github.com/grey-code/5286786

By Toralf:
Forum thread: http://www.autohotkey.com/board/topic/54987-sift3-super-fast-and-accurate-string-distance-algorithm/#entry345400

Basic idea for SIFT3 code by Siderite Zackwehdex
http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html

  Took idea to normalize it to longest string from Brad Wood
http://www.bradwood.com/string_compare/

Own work:
- when character only differ in case, LSC is a 0.8 match for this character
- modified code for speed, might lead to different results compared to original code
- optimized for speed (30% faster then original SIFT3 and 13.3 times faster than basic Levenshtein distance)
*/
StrDiff(str1, str2, maxOffset:=5)
{
	if (str1 = str2)
		return (str1 == str2 ? 0/1 : 0.2/StrLen(str1))
	if (str1 = "" || str2 = "")
		return (str1 = str2 ? 0/1 : 1/1)

	StringSplit, n, str1
	StringSplit, m, str2

	ni := 1, mi := 1, lcs := 0
	while ((ni <= n0) && (mi <= m0)) {
		if (n%ni% == m%mi%)
			lcs++
		else if (n%ni% = m%mi%)
			lcs += 0.8
		else {
			Loop, % maxOffset {
				oi := ni + A_Index, pi := mi + A_Index
				if ((n%oi% = m%mi%) && (oi <= n0)) {
					ni := oi, lcs += (n%oi% == m%mi% ? 1 : 0.8)
					break
				}
				if ((n%ni% = m%pi%) && (pi <= m0)) {
					mi := pi, lcs += (n%ni% == m%pi% ? 1 : 0.8)
					break
				}
			}
		}

	ni++, mi++
	}

	return ((n0 + m0)/2 - lcs) / (n0 > m0 ? n0 : m0)
}
