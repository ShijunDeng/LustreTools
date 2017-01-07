# description:   An objective function describes the goal of the optimization.
#                It generates a score that reflects the performance of a workload.
#                The score is used to judge the merit of a rule set.
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-06
#
import sys

candidate_avg_bw = 1
candidate_avg_var = 2
afactor = 0.5
k = 0.5


def afactor_score():
    score = candidate_avg_bw - afactor * candidate_avg_var
    if score > 0:
        return score
    return 0


def cv_score():
    if candidate_avg_var * 1.0 / candidate_avg_bw < k:
        return candidate_avg_bw
    return 0


objective_function = {"cv_score": cv_score, "afactor_score": afactor_score}


def get_score(objective_model="afactor_score"):
    return objective_function.get(objective_model)()


print(get_score())
