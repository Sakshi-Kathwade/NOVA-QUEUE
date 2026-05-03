package com.example.quize app;

import androidx.appcompat.app.AppCompatActivity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity {

    TextView questionText, scoreText;
    Button option1, option2, option3, option4, nextBtn;

    String questions[] = {
            "What is the capital of India?",
            "Which language is used for Android development?",
            "Who is the founder of Microsoft?",
            "Which planet is known as Red Planet?",
            "What is 2 + 2?"
    };

    String options[][] = {
            {"Mumbai", "Delhi", "Pune", "Chennai"},
            {"Python", "Java", "C++", "Swift"},
            {"Elon Musk", "Bill Gates", "Steve Jobs", "Mark Zuckerberg"},
            {"Earth", "Mars", "Jupiter", "Venus"},
            {"2", "3", "4", "5"}
    };

    String answers[] = {
            "Delhi",
            "Java",
            "Bill Gates",
            "Mars",
            "4"
    };

    int currentQuestion = 0;
    int score = 0;
    boolean answered = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        questionText = findViewById(R.id.question);
        scoreText = findViewById(R.id.score);
        option1 = findViewById(R.id.opt1);
        option2 = findViewById(R.id.opt2);
        option3 = findViewById(R.id.opt3);
        option4 = findViewById(R.id.opt4);
        nextBtn = findViewById(R.id.nextBtn);

        loadQuestion();

        View.OnClickListener listener = view -> {
            if (!answered) {
                Button selected = (Button) view;
                checkAnswer(selected);
            }
        };

        option1.setOnClickListener(listener);
        option2.setOnClickListener(listener);
        option3.setOnClickListener(listener);
        option4.setOnClickListener(listener);

        nextBtn.setOnClickListener(v -> {
            currentQuestion++;
            if (currentQuestion < questions.length) {
                loadQuestion();
            } else {
                Toast.makeText(this, "Quiz Finished! Score: " + score, Toast.LENGTH_LONG).show();
                currentQuestion = 0;
                score = 0;
                loadQuestion();
            }
        });
    }

    void loadQuestion() {
        answered = false;
        resetOptions();

        questionText.setText(questions[currentQuestion]);
        option1.setText(options[currentQuestion][0]);
        option2.setText(options[currentQuestion][1]);
        option3.setText(options[currentQuestion][2]);
        option4.setText(options[currentQuestion][3]);

        scoreText.setText("Score: " + score);
    }

    void checkAnswer(Button selected) {
        answered = true;

        if (selected.getText().toString().equals(answers[currentQuestion])) {
            selected.setBackgroundColor(Color.GREEN);
            score++;
        } else {
            selected.setBackgroundColor(Color.RED);
            highlightCorrect();
        }
    }

    void highlightCorrect() {
        if (option1.getText().equals(answers[currentQuestion]))
            option1.setBackgroundColor(Color.GREEN);
        if (option2.getText().equals(answers[currentQuestion]))
            option2.setBackgroundColor(Color.GREEN);
        if (option3.getText().equals(answers[currentQuestion]))
            option3.setBackgroundColor(Color.GREEN);
        if (option4.getText().equals(answers[currentQuestion]))
            option4.setBackgroundColor(Color.GREEN);
    }

    void resetOptions() {
        option1.setBackgroundColor(Color.parseColor("#6200EE"));
        option2.setBackgroundColor(Color.parseColor("#6200EE"));
        option3.setBackgroundColor(Color.parseColor("#6200EE"));
        option4.setBackgroundColor(Color.parseColor("#6200EE"));
    }
}