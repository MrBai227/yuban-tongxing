@extends('admin.layout')

@section('content')
<div class="card">
    <div class="flex items-center justify-between mb-3">
        <h2>练习打卡记录</h2>
        <a class="btn btn-primary" href="{{ route('admin.practice_logs.create') }}">新增打卡记录</a>
    </div>
    <div class="table-wrapper">
        <table class="table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>用户</th>
                    <th>总时长(秒)</th>
                    <th>轻声起音</th>
                    <th>延长发音</th>
                    <th>朗读</th>
                    <th>备注</th>
                    <th>创建时间</th>
                </tr>
            </thead>
            <tbody>
            @foreach($logs as $log)
                <tr>
                    <td>{{ $log->id }}</td>
                    <td>{{ optional($log->user)->name }} (#{{ $log->user_id }})</td>
                    <td>{{ $log->duration_seconds }}</td>
                    <td>{{ $log->soft_onset_seconds }}</td>
                    <td>{{ $log->prolonged_seconds }}</td>
                    <td>{{ $log->reading_seconds }}</td>
                    <td>{{ $log->note }}</td>
                    <td>{{ $log->created_at }}</td>
                </tr>
            @endforeach
            </tbody>
        </table>
    </div>
    <div class="mt-3">{{ $logs->links() }}</div>
</div>
@endsection