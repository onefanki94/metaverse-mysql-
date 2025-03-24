/* 2025-03-24 미션 */

/*    WHERE 미션     */

-- 📌 결제한 학생 목록 조회 (IN 활용)
SELECT username FROM users WHERE user_id in(SELECT user_id FROM payments);
-- 📌 퀴즈에 응시하지 않은 학생 목록 조회 (NOT IN 활용)
SELECT username FROM users WHERE user_id NOT IN (SELECT user_id FROM payments);
-- 📌 과제가 있는 강의 목록 조회 (EXISTS 활용)
SELECT u.username FROM users u WHERE EXISTS (SELECT 1 FROM payments p WHERE u.user_id = p.user_id);

/*       SELECT 미션        */

-- 📌 퀴즈 점수와 퀴즈별 평균 점수 비교
SELECT u.username "수강생 이름", q.score "점수", (SELECT avg(q2.score)   FROM quiz_attempts q2  WHERE q2.user_id = u.user_id ) AS "해당 유저 평균점수" FROM users u 
INNER JOIN quiz_attempts q ON u.user_id = q.user_id;
-- 📌 결제 금액과 해당 강좌의 수강생 수 출력
SELECT p2.amount, (SELECT count(c.course_id) FROM courses c WHERE p2.course_id = c.course_id ) AS "강좌 수강생수 " FROM  users u
INNER JOIN payments p2 ON p2.user_id = u.user_id;

-- 📌 학생별 평균 결제 금액 조회
SELECT u.username, p.amount,(SELECT avg(p2.amount) FROM payments p2 WHERE p2.course_id = p.course_id ) AS avg_price FROM users u
INNER JOIN payments p ON p.user_id = u.user_id;

/*        FROM 미션         */
-- 📌 평균 점수보다 높은 퀴즈 조회
SELECT q.attempt_id, q.avg_score FROM (SELECT attempt_id, avg(score) AS avg_score FROM quiz_attempts  GROUP BY attempt_id) AS q   WHERE q.avg_score > 50;
-- 퀴즈id 랑 score, quiz_attempts 
SELECT avg(score) FROM quiz_attempts;
-- 📌 결제 총액 평균보다 큰 강좌 조회
SELECT p.course_id, p.avg_amount FROM (SELECT course_id, avg(amount) AS avg_amount FROM payments GROUP BY course_id) AS p WHERE p.avg_amount > 250;
SELECT avg(amount) FROM payments; --  평균 결제 금액 251.122445
-- 📌 평균 과제 수보다 많은 강의 조회
SELECT l.lesson_id, l.count_lesson FROM (SELECT lesson_id, count(assignment_id) AS count_lesson FROM  assignments GROUP BY lesson_id) AS l WHERE l.count_lesson;


/* ==========================
📌 VIEW 활용 미션
========================== */

-- 📌 퀴즈 응시자의 평균 점수보다 높은 학생만 표시하는 뷰 생성
CREATE VIEW quiz_students AS 
SELECT 
			u.username,
			q.quiz_id,
			avg(score) AS avg_score
		FROM users u
	INNER JOIN quiz_attempts qa ON u.user_id = qa.user_id
	INNER JOIN quizzes q ON qa.quiz_id = q.quiz_id
GROUP BY u.username, q.quiz_id having avg_score > 50;

				SELECT * FROM quiz_students;
			
-- 📌 특정 강좌의 결제 내역만 필터링하는 뷰 생성 (강좌 ID 3번에 해당하는 결제 내역)
CREATE VIEW quiz_payments AS
SELECT 
				p.payment_id,
				p.amount,
				c.course_id,
				u.username
			FROM payments p
		INNER JOIN users u ON u.user_id = p.user_id
		INNER JOIN courses c ON c.course_id = p.course_id
		GROUP BY p.amount, c.course_id, p.payment_id HAVING course_id =3;

SELECT * FROM quiz_payments;

/*      윈도우 함수 미션      */
-- 📌 각 강좌에서 상위 3명의 학생을 `RANK()`를 이용해 조회하세요.
SELECT quiz_id, score,rank_desc
FROM (
    SELECT
        quiz_id,
        score,
        RANK() OVER (PARTITION BY quiz_id ORDER BY score desc) AS rank_desc
    FROM quiz_attempts
) AS rank_desc
WHERE rank_desc <= 3;

-- --------------------------------------------

SELECT
			quiz_id,
			user_id,
			score,
			RANK() OVER(PARTITION BY quiz_id ORDER BY score DESC) AS rank_value,
			DENSE_RANK() OVER (PARTITION BY quiz_id ORDER BY score DESC) AS dense_rank_value,
			ROW_NUMBER() OVER(PARTITION BY quiz_id ORDER BY score DESC) AS row_num_value
		FROM QUIZ_ATTEMPTS
	WHERE quiz_id = 1;

-- 📌 `DENSE_RANK()`를 이용해 상위 5명까지 출력하고 순위 차이를 비교하세요.
SELECT quiz_id, 
					score, 
					rank_desc, RANK() over(PARTITION BY quiz_id ORDER BY score desc) AS dense_rank_desc
	FROM (
		SELECT quiz_id, score, 
				DENSE_RANK() OVER(PARTITION BY quiz_id ORDER BY score DESC) AS rank_desc
	FROM quiz_attempts
				) AS dense_rank_desc WHERE rank_desc <=5;

-- 📌 `ROW_NUMBER()`를 이용해 학생별로 최근 응시한 퀴즈 1개만 조회하세요.
SELECT quiz_id, attempted_at, row_num_quiz
FROM (
    SELECT quiz_id, attempted_at,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY attempted_at DESC) AS row_num_quiz
    FROM quiz_attempts
) AS row_num_quiz
WHERE row_num_quiz = 1;


/*       미션        */

-- 📌 두 개의 강좌를 결제한 후, 첫 번째 결제만 유지하고 두 번째 결제는 취소하세요.
START TRANSACTION;


INSERT INTO payments(user_id, course_id, amount, payment_status)
VALUES (10001, 100, 100.0, "pending");


SAVEPOINT payment1;


INSERT INTO payments(user_id, course_id, amount, payment_status)
VALUES (10001, 200, 150.0, "pending");
SELECT * FROM payments WHERE user_id = 10001;

ROLLBACK TO SAVEPOINT payment1;


SELECT * FROM payments WHERE user_id = 10001;
COMMIT;


