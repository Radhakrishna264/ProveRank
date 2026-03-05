#!/bin/bash
WS=~/workspace

echo "=== exam_patch.js accept-terms handler ==="
grep -n "accept-terms" $WS/src/routes/exam_patch.js

echo ""
echo "=== exam_patch.js lines 50-70 ==="
sed -n '50,70p' $WS/src/routes/exam_patch.js

echo ""
echo "=== attemptRoutes.js lines 1-20 ==="
sed -n '1,20p' $WS/src/routes/attemptRoutes.js

echo ""
echo "=== attemptRoutes.js save-answer handler ==="
grep -n "save-answer" $WS/src/routes/attemptRoutes.js

echo ""
echo "=== exam_patch.js top 5 lines (imports) ==="
head -5 $WS/src/routes/exam_patch.js

echo ""
echo "=== exam.js top 5 lines (imports) ==="
head -5 $WS/src/routes/exam.js

echo ""
echo "=== Attempt.js model - mongoose.model line ==="
grep -n "mongoose.model\|collection" $WS/src/models/Attempt.js

echo ""
echo "=== Exam.js model - mongoose.model line ==="
grep -n "mongoose.model\|collection" $WS/src/models/Exam.js
