# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule AntikytheraCore.ErlangLogTranslator do
  @moduledoc """
  Translator for `Logger`, installed via application config.

  Most of translations are delegated to `Logger.Translator`;
  this translator neglects messages of the following types:

  - SASL progress report
  - error log emitted by syn about mnesia down event (when a node in the cluster is terminated)
  - supervisor report on brutal kill of a worker process in PoolSup (when a too-long-running worker is stopped)
  """

  # TODO: remove after upgrading to Erlang/OTP 21+
  def translate(_min_level, :info, :report, {:progress, _data}) do
    :skip
  end

  def translate(_min_level, :info, :report, {{_reporter, :progress}, _data}) do
    :skip
  end

  def translate(_min_level, :error, :format, {'Received a MNESIA down event' ++ _, _}) do
    :skip
  end

  # TODO: remove after upgrading to Erlang/OTP 21+
  def translate(min_level, :error, :report, {:supervisor_report, kw} = message) do
    case Keyword.get(kw, :supervisor) do
      {_pid, PoolSup.Callback} -> :skip
      _otherwise -> Logger.Translator.translate(min_level, :error, :report, message)
    end
  end

  def translate(min_level, :error, :report, {{:supervisor, :child_terminated}, kw} = message) do
    case Keyword.get(kw, :supervisor) do
      {_pid, PoolSup.Callback} -> :skip
      _otherwise -> Logger.Translator.translate(min_level, :error, :report, message)
    end
  end

  def translate(min_level, level, kind, message) do
    Logger.Translator.translate(min_level, level, kind, message)
  end
end
