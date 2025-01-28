import numpy as np
import matplotlib.pyplot as plt
import time
import pandas as pd
import math
import random


class ExperiencePool:
    """
    Experience pool for collecting trajectories.
    """
    def __init__(self):
        self.states = []
        self.actions = []
        self.rewards = []
        self.dones = []

    def add(self, state, action, reward, done):
        self.states.append(state)  # sometime state is also called obs (observation)
        self.actions.append(action)
        self.rewards.append(reward)
        self.dones.append(done)

    def __len__(self):
        return len(self.states)



column_list = [
    "start",                # start
    "queue_type",                # q->queue_type
    "qdelay_reference",          # pprms->qdelay_ref
    "tupdate",               # pprms->tupdate
    "max_burst",            # pprms->max_burst
    "max_ecn_threshold",         # pprms->max_ecnth
    "alpha_coefficient",         # pprms->alpha
    "beta_coefficient",          # pprms->beta
    "flags",                     # pprms->flags
    "burst_allowance",           # pst->burst_allowance
    "drop_probability",          # pst->drop_prob
    "current_queue_delay",       # pst->current_qdelay
    "previous_queue_delay",      # pst->qdelay_old
    "accumulated_probability",   # pst->accu_prob
    "measurement_start_time",    # pst->measurement_start
    "average_dequeue_time",      # pst->avg_dq_time
    "dequeue_count",             # pst->dq_count
    "status_flags",              # pst->sflags
    "total_packets",             # q->stats.tot_pkts
    "total_bytes",               # q->stats.tot_bytes
    "queue_length",              # q->stats.length
    "length_in_bytes",           # q->stats.len_bytes
    "total_drops",               # q->stats.drops
    "dequeue_action",            # dequeue_action
    "end"                   # end
]


df=pd.read_csv("llmrawdata.txt",names=column_list,header=None)

df=df.drop(columns=['start', 'end'])
df["reward"] = df["current_queue_delay"]


df.describe()


import pickle
exp_pool = ExperiencePool()
# Initialize the global reward variable
global_reward = 0

# Iterate through each row and update the global reward variable
for index, row in df.iterrows():
    # global_reward += row['current_queue_delay']
    state = np.array(row[:])
    exp_pool.add(state=state, action=row['dequeue_action'], reward=row['current_queue_delay'], done=row['current_queue_delay'])



pickle_save_path='exp_pool.pkl'
pickle.dump(exp_pool, open( pickle_save_path, 'wb'))
print(f"Done. Experience pool saved at:", pickle_save_path)
