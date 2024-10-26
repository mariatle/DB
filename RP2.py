import time
from mpi4py import MPI
import numpy as np
from numpy.linalg import norm
import sys
import matplotlib.pyplot as plt

np.random.seed(42)

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

MATRIX_SIZE = 2 ** 13
MATRIX_SPLIT = int(sys.argv[1])

# Создание матрицы A
a = np.zeros((MATRIX_SIZE, MATRIX_SIZE), dtype=np.double)
for i in range(MATRIX_SIZE):
    for j in range(MATRIX_SIZE):
        if i == j:
            a[i, j] = 2
        else:
            a[i, j] = 1

# Создание вектора b и x
b = np.ones(MATRIX_SIZE, dtype=np.double) * (2 ** 13 + 1)
x = np.zeros(MATRIX_SIZE, dtype=np.double)

epsilon = 0.00001


def mult_matrix_by_vector(m, v):
    v = v[:, None]
    #содержит локальную часть матрицы для текущего процесса
    part_a = np.empty(shape=(MATRIX_SIZE // MATRIX_SPLIT,
                             MATRIX_SIZE), dtype=np.double)
    # передача частей на каждый процесс
    comm.Scatter(m, part_a, root=0)
#операция умножения локальной части матрицы 𝑝𝑎𝑟𝑡𝑎 на вектор 𝑣.
#Результат — это вектор, который хранит результаты умножения локальной части матрицы на вектор 𝑥.
    part_a = part_a @ v
    res = None
    if rank == 0:
        res = np.empty(shape=(MATRIX_SIZE, 1), dtype=np.double)
    # сбор частей
    comm.Gather(part_a, res, root=0)

    return comm.bcast(res, root=0).T[0]


def main():
    global x

    # Разрезание вектора b
    local_b = np.empty(MATRIX_SIZE // size, dtype=np.double)
    comm.Scatter(b, local_b, root=0)

    # Разрезание вектора x
    local_x = np.zeros(MATRIX_SIZE // size, dtype=np.double)

    old_crit = 0
    i = 0
    #итерационный процесс
    while True:
        i += 1
        y = mult_matrix_by_vector(a, x) - local_b  # Используем local_b
        ay = mult_matrix_by_vector(a, y)
        flag = False
        #критерий сходимости
        if rank == 0:
            crit = norm(y) / norm(b)
            if crit < epsilon or crit == old_crit:
                flag = True
            else:
                old_crit = crit
                tao = (y.dot(ay)) / (ay.dot(ay))
                x = x - tao * y

        if comm.bcast(flag, root=0):
            break
        x = comm.bcast(x, root=0)


if __name__ == '__main__':
    time_results = []
    for cores in [1, 2, 4, 8, 16]:
        if rank == 0:
            t_start = time.time()
        main()
        if rank == 0:
            elapsed_time = time.time() - t_start
            time_results.append(elapsed_time)
            print(f"Число ядер: {cores}, Время: {elapsed_time:.2f} секунд")

    # Визуализация результатов
    if rank == 0:
        speedup = [time_results[0] / t for t in time_results]
        efficiency = [s / p for s, p in zip(speedup, [1, 2, 4, 8, 16])]

        # Визуализация времени работы
        plt.figure(figsize=(10, 6))
        plt.subplot(1, 3, 1)
        plt.plot([1, 2, 4, 8, 16], time_results, marker='o', color='b', label='Время')
        plt.xlabel("Число ядер")
        plt.ylabel("Время выполнения (с)")
        plt.title("Время выполнения в зависимости от числа ядер")
        plt.grid()

        # Визуализация ускорения
        plt.subplot(1, 3, 2)
        plt.plot([1, 2, 4, 8, 16], speedup, marker='o', color='g', label='Ускорение')
        plt.xlabel("Число ядер")
        plt.ylabel("Ускорение")
        plt.title("Ускорение в зависимости от числа ядер")
        plt.grid()

        # Визуализация эффективности
        plt.subplot(1, 3, 3)
        plt.plot([1, 2, 4, 8, 16], efficiency, marker='o', color='r', label='Эффективность')
        plt.xlabel("Число ядер")
        plt.ylabel("Эффективность")
        plt.title("Эффективность в зависимости от числа ядер")
        plt.grid()

        plt.tight_layout()
        plt.show()
